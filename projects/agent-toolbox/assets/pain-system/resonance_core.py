import time
import logging
import json
import os
import threading
import numpy as np
import psutil
from manifold import TemporalManifold
from kernel import KernelPain

# Configure logging for the Resonance Core
from logging.handlers import RotatingFileHandler
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] RESONANCE: %(message)s',
    handlers=[
        RotatingFileHandler("resonance.log", maxBytes=5*1024*1024, backupCount=3),
        logging.StreamHandler()
    ]
)

from voxel.world_engine import WorldEngine
from physics_engine import PhysicsEngine, PhysicalEntity
from game_detector import gaming


def _write_state_async(poly_objs):
    """Write kernelpain_state.json in a background thread — non-blocking."""
    try:
        import json, os, time
        from utils.path_resolver import get_state_file_path
        state_file = get_state_file_path()
        existing = {}
        if os.path.exists(state_file):
            try:
                with open(state_file, "r") as f:
                    existing = json.load(f)
            except (OSError, json.JSONDecodeError):
                pass
        existing["polyhedral_objects"] = poly_objs
        existing["last_boot"] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        if "zodiac" not in existing:
            existing["zodiac"] = "Pain"
        with open(state_file, "w") as f:
            json.dump(existing, f, indent=4)
    except PermissionError:
        pass
    except Exception:
        pass

# ---------------------------------------------------------------------------
# Resonance Core constants
# ---------------------------------------------------------------------------
TICK_RATE_HZ       = 5                       # 5 Hz — clean 200ms tick, stable
AGENT_TICK_DIVISOR = 5                       # Agent logic at 1 Hz
WORLD_TICK_DIVISOR = 5                       # World refresh at 1 Hz
STATE_WRITE_DIVISOR = 20                     # State write every 4s (reduced from 5 to lower I/O)
JITTER_LOG_EVERY   = 10                      # Only log jitter every Nth tick (prevents feedback loop)
# GPU-data-driven gaming sleep (seconds) — tied to actual GPU load, not a math constant
_GAMING_SLEEP_TABLE = ((90, 5.0), (70, 2.0), (0, 1.0))
MODE_DEBOUNCE_TICKS = 2                      # Require N stable ticks before mode transition
SPAWN_CENTER       = [16.0, 10.0, 16.0]   # Agent spawn position in 32³ voxel space
GRID_CENTER_X      = 16.0        # X-offset when translating to render coords
GRID_CENTER_Y      = 15.0        # Y-offset when translating to render coords
GRID_CENTER_Z      = 16.0        # Z-offset when translating to render coords
LIFT_PER_LEVEL     = 6.0         # Upward lift force added per skill level
SPRING_DEVA_X_SCALE = 3.0        # Target X = len(sync_targets) * scale
SPRING_ASURA_POS   = [8.0, 22.0, 12.0]   # AsuraPath anchor in voxel space
SPRING_PRETA_POS   = [24.0, 4.0,  8.0]   # PretaPath anchor in voxel space
JITTER_WARN_MS     = 1000        # Log a warning when tick takes longer than this (ms)
STABILIZE_SLEEP    = 0.5         # Seconds to pause after a stabilisation cycle

class ResonanceCore:
    """
    THE RESONANCE CORE: A Discrete Dynamical System
    S_{t+1} = F(S_t) where F = R ∘ L ∘ P ∘ W ∘ I
    """
    def __init__(self, kernel=None, manifold=None, on_tick_callback=None):
        self.kernel = kernel or KernelPain()
        self.manifold = manifold or TemporalManifold(process_count=12)
        self.on_tick_callback = on_tick_callback
        
        # Fixed Delta T — clean 5 Hz, self-correcting via deadline scheduling
        self.delta_t = 1.0 / TICK_RATE_HZ  # 0.2s
        self.tick_count = 0
        self.is_running = False
        
        # Engines (Functional Components of F)
        self.world = WorldEngine()
        self.physics = PhysicsEngine(delta_t=self.delta_t)
        self.agents = []
        self._agents_lock = threading.Lock()
        
        # Initialise sampled metrics so _phase_physics can consume them on tick 1
        self._system_pressure = 0.0
        self._cpu_percent = 0.0
        self._mem_percent = 0.0
        self._next_tick_deadline = 0.0
        self.last_gaming_mode = 'idle'
        self._pending_mode = None        # debounce: candidate mode not yet committed
        self._pending_mode_ticks = 0     # how many ticks it's been stable
        self._last_gpu = 0.0             # cached GPU usage for sleep scaling
        logging.info(f"Resonance Core initialized. DT = {self.delta_t}s ({TICK_RATE_HZ} Hz).")

    def add_agent(self, agent):
        """Register an agent to the Logic Phase (L)."""
        with self._agents_lock:
            self.agents.append(agent)
        agent.physical_proxy = PhysicalEntity(position=SPAWN_CENTER)
        self.physics.add_entity(agent.physical_proxy)
        logging.info(f"Agent {agent.name} bound to Resonance Core (Logic & Physics).")

    def _gaming_sleep_for_gpu(self, gpu):
        """Return sleep time based on actual GPU usage, not a math constant."""
        for threshold, sleep_time in _GAMING_SLEEP_TABLE:
            if gpu >= threshold:
                return sleep_time
        return self.delta_t  # idle — use normal tick rate

    def start_heartbeat(self):
        """Self-correcting deadline tick loop with GPU-data-driven gaming sleep."""
        self.is_running = True
        self._next_tick_deadline = time.perf_counter()
        logging.info("Resonance Core HEARTBEAT started (5 Hz, self-correcting).")
        while self.is_running:
            self.resonance_step()
            
            # Compute sleep based on gaming mode + GPU usage (data-driven)
            mode = gaming.gaming_mode()
            if mode == 'idle':
                # Self-correcting deadline: sleep exactly until next tick is due
                now = time.perf_counter()
                sleep_time = max(0, self._next_tick_deadline - now)
                self._next_tick_deadline = now + sleep_time + self.delta_t
            else:
                s = gaming.summary()
                self._last_gpu = s['gpu_usage'] if s else 0.0
                sleep_time = self._gaming_sleep_for_gpu(self._last_gpu)
                # Reset deadline so next idle tick starts fresh
                self._next_tick_deadline = time.perf_counter() + self.delta_t
                
            time.sleep(sleep_time)

    def resonance_step(self):
        """
        S_{t+1} = R(L(P(W(I(S_t)))))
        """
        self.tick_count += 1
        start_time = time.perf_counter()

        try:
            # I: INPUT PHASE
            t0 = time.perf_counter()
            self._phase_input()
            t_input = time.perf_counter() - t0

            # Dynamic gamer mode check with debounce (prevents flip-flop from brief alt-tabs)
            raw_mode = gaming.gaming_mode()
            if raw_mode == self._pending_mode:
                self._pending_mode_ticks += 1
            else:
                self._pending_mode = raw_mode
                self._pending_mode_ticks = 1

            # Commit mode transition only after debounce threshold
            if self._pending_mode_ticks >= MODE_DEBOUNCE_TICKS and raw_mode != self.last_gaming_mode:
                logging.info(f"Gaming mode transition: {self.last_gaming_mode} -> {raw_mode}")
                self._commit_mode_transition(raw_mode)
                self.last_gaming_mode = raw_mode

            if self.last_gaming_mode == 'active':
                return

            # W: WORLD PHASE (Chunks & Worldgen)
            t1 = time.perf_counter()
            self._phase_world()
            t_world = time.perf_counter() - t1

            # P: PHYSICS PHASE (Integration & Constraints)
            t2 = time.perf_counter()
            self._phase_physics()
            t_physics = time.perf_counter() - t2

            # L: LOGIC PHASE (Agents & AI)
            t3 = time.perf_counter()
            self._phase_logic()
            t_logic = time.perf_counter() - t3

            # R: RENDER PHASE (State Presentation)
            t4 = time.perf_counter()
            self._phase_render()
            t_render = time.perf_counter() - t4

            if self.on_tick_callback:
                self.on_tick_callback(self.tick_count)

        except Exception as e:
            logging.error(f"Tick {self.tick_count} DISCORDANCE: {e}")
            self._stabilize()

        end_time = time.perf_counter()
        tick_duration = end_time - start_time
        
        if tick_duration * 1000 > JITTER_WARN_MS and self.tick_count % JITTER_LOG_EVERY == 0:
            logging.warning(f"Resonance Jitter: {tick_duration*1000:.2f}ms | input={t_input*1000:.1f} world={t_world*1000:.1f} physics={t_physics*1000:.1f} logic={t_logic*1000:.1f} render={t_render*1000:.1f}")

    def _commit_mode_transition(self, new_mode):
        """Apply a debounced gaming mode transition."""
        with self._agents_lock:
            human_agent = next((a for a in self.agents if a.name == "HumanPath"), None)
        if not human_agent:
            return
        if new_mode == 'active':
            logging.info("[Resonance] Active gaming. Suspending HumanPath watchdog.")
            try:
                human_agent.observer.unschedule_all()
                human_agent.telemetry['strategy'] = "GAMING_SUSPEND"
            except Exception as e:
                logging.error(f"[Resonance] Failed to unschedule HumanPath observer: {e}")
        elif new_mode in ('idle', 'background'):
            if human_agent.telemetry.get('strategy') == "GAMING_SUSPEND":
                logging.info("[Resonance] Gaming ceased or backgrounded. Resuming HumanPath watchdog.")
                from agents.human_path import WATCH_DIR
                try:
                    human_agent.observer.schedule(human_agent.handler, WATCH_DIR, recursive=True)
                    human_agent.telemetry['strategy'] = "NOMINAL"
                except Exception as e:
                    logging.error(f"[Resonance] Failed to reschedule HumanPath observer: {e}")

    def _phase_input(self):
        """I: Input Phase — sample current system pressure into shared manifold state."""
        cpu = psutil.cpu_percent(interval=None)
        mem = psutil.virtual_memory().percent
        self._system_pressure = cpu / 100.0
        # Expose metrics so other phases can read without re-sampling
        self._cpu_percent = cpu
        self._mem_percent = mem

    def _phase_world(self):
        """W: World Phase. Advanced asynchronously."""
        # Advance the Temporal Manifold (spatial reality) using sampled pressure
        self.manifold.step(self._system_pressure)
        
        # Periodically refresh the CPU voxel resource map (every 1Hz / 20 ticks)
        if self.tick_count % WORLD_TICK_DIVISOR == 0:
            chunk = self.world.load_chunk((0, 0, 0))
            self.world.update_resource_map(chunk)

    def _phase_physics(self):
        """P: Physics Phase. Numerical Integration."""
        # Use pressure already sampled in Input Phase (avoids a second psutil call)
        self.physics.update_gravity(self._cpu_percent)
        
        # Calculate tick execution delay to feed tremor jitter (only in idle mode)
        if self.last_gaming_mode == 'idle' and self._next_tick_deadline > 0:
            delay = time.perf_counter() - (self._next_tick_deadline - self.delta_t)
            self.physics.set_jitter(delay)
        else:
            self.physics.jitter_tremor = 0.0
            
        self.physics.step()

    def _phase_logic(self):
        """L: Logic Phase. Entity state transitions (at 1Hz)."""
        # Agents originally ran at 1Hz. We maintain this frequency.
        if self.tick_count % AGENT_TICK_DIVISOR == 0:
            with self._agents_lock:
                agent_snapshot = list(self.agents)
            for agent in agent_snapshot:
                try:
                    if hasattr(agent, 'observe'): agent.observe()
                    if hasattr(agent, 'process'): agent.process()
                    if hasattr(agent, 'execute'): agent.execute()
                except Exception as e:
                    logging.error(f"Logic failure in agent {agent.name}: {e}")
                    
            # Update physical lift forces and target core anchors based on active workloads
            for agent in agent_snapshot:
                if hasattr(agent, 'physical_proxy') and agent.physical_proxy is not None:
                    entity = agent.physical_proxy
                    skills = agent.skills.get_all_skills()
                    top_skill_level = 1
                    if skills:
                        top_skill_level = max(s.level for s in skills.values())
                    
                    # Level scaling lift counters gravity
                    entity['lift'] = np.array([0.0, float(top_skill_level * LIFT_PER_LEVEL), 0.0])
                    
                    # Anchor target core positions (Linguistic Affinity Pull)
                    if agent.name == "DevaPath" and 'sync_targets' in agent.telemetry:
                        targets = agent.telemetry['sync_targets']
                        if targets:
                            entity['target_pos'] = np.array([float(len(targets) * SPRING_DEVA_X_SCALE), 16.0, 16.0])
                    elif agent.name == "AsuraPath" and 'forge_targets' in agent.intel:
                        targets = agent.intel['forge_targets']
                        if targets:
                            entity['target_pos'] = np.array(SPRING_ASURA_POS)
                    elif agent.name == "PretaPath" and 'targets' in agent.telemetry:
                        targets = agent.telemetry['targets']
                        if targets:
                            entity['target_pos'] = np.array(SPRING_PRETA_POS)
                    else:
                        entity['target_pos'] = None

    def _phase_render(self):
        """Finalize state for the bridge and visualization layers."""
        with self._agents_lock:
            agent_snapshot = list(self.agents)
        poly_objs = []
        
        # Color & shape mapping for visualizer
        agent_configs = {
            "Pain": {"color": "#00FF41", "type": "sphere"},
            "DevaPath": {"color": "#8a2be2", "type": "sphere"},
            "AsuraPath": {"color": "#ff2d00", "type": "tetra"},
            "HumanPath": {"color": "#ffaa00", "type": "tetra"},
            "AnimalPath": {"color": "#00ff00", "type": "sphere"},
            "PretaPath": {"color": "#4b0082", "type": "box"},
            "NarakaPath": {"color": "#ff00ff", "type": "box"},
        }
        
        for i, agent in enumerate(agent_snapshot):
            if hasattr(agent, 'physical_proxy') and agent.physical_proxy is not None:
                pos = agent.physical_proxy['position'].tolist()
                config = agent_configs.get(agent.name, {"color": "#ffffff", "type": "box"})
                # Scale coordinates to offset center around 0 on dashboard
                poly_objs.append({
                    "id": i + 1,
                    "name": agent.name,
                    "pos": [round(pos[0] - GRID_CENTER_X, 2), round(pos[1] - GRID_CENTER_Y, 2), round(pos[2] - GRID_CENTER_Z, 2)],
                    "color": config["color"],
                    "type": config["type"]
                })
                
        # Spawn dark matter anomaly spheres (Black Receivers) for high-CPU processes
        for agent in agent_snapshot:
            if agent.name == "PretaPath" and 'targets' in agent.telemetry:
                for target in agent.telemetry['targets']:
                    poly_objs.append({
                        "id": len(poly_objs) + 1,
                        "name": f"ANOMALY_{target['pid']}",
                        "pos": [12.0, -10.0, 8.0],
                        "color": "#111111", # Dark Matter black
                        "type": "sphere"
                    })
        
        # Cache polyhedral objects for the API endpoint (in-memory, every tick)
        self._cached_poly_objs = poly_objs
                    
        # Throttle state file writes and run in background thread
        if self.tick_count % STATE_WRITE_DIVISOR == 0:
            # Write state asynchronously — non-blocking disk I/O
            poly_snapshot = poly_objs
            state_write_thread = threading.Thread(
                target=_write_state_async,
                args=(poly_snapshot,),
                daemon=True
            )
            state_write_thread.start()

    def _stabilize(self):
        """The Sovereign Recovery Protocol — re-aligns state after a discordant tick."""
        logging.info("RECOVERY: Re-aligning temporal resonance vectors...")
        try:
            with self._agents_lock:
                agent_snapshot = list(self.agents)
            for agent in agent_snapshot:
                if hasattr(agent, 'physical_proxy') and agent.physical_proxy is not None:
                    agent.physical_proxy['velocity'] = np.zeros(3)
                    agent.physical_proxy['position'] = np.array(SPAWN_CENTER, dtype=float)
            logging.info("RECOVERY: Agent physical proxies re-centred.")

            # 2. Re-initialise the manifold positions to break any stuck attractors
            self.manifold.positions = np.random.rand(
                self.manifold.process_count, 2
            )
            logging.info("RECOVERY: Manifold positions randomised.")

            # 3. Brief sleep to let system pressure subside before next tick
            time.sleep(STABILIZE_SLEEP)
        except Exception as e:
            logging.error(f"RECOVERY: Stabilisation itself failed: {e}")

if __name__ == "__main__":
    # Test the core in isolation
    core = ResonanceCore()
    try:
        core.start_heartbeat()
    except KeyboardInterrupt:
        core.is_running = False
        print("\n[Resonance] Heartbeat terminated by Architect.")
