"""
ThoughtFactory — Production Line for the Thought Engine
=========================================================
Tracks every thought as it moves through Pain's processing pipeline.
Each thought is a work order. Each pipeline stage is a station.
The factory floor is visible in real time via /factory/state.

Pipeline Stations:
  1. INTAKE        — raw query received, energy calculated
  2. CLASSIFIER    — domain scored, voxel position assigned
  3. ROUTING_FORGE — physics probe fired, mode selected
  4. AGENT_ASSEMBLY— six path agents inspect and respond
  5. SYNTHESIS     — sovereign synthesizer compresses outputs
  6. QA_GATE       — sufficiency check, phi consulted if needed
  7. SHIPPING      — response dispatched, thought written to voxel

Each work order tracks:
  - which station it's at
  - how long it spent at each station (ms)
  - what was produced at each station
  - final output quality score
"""

import time
import threading
import uuid
from collections import deque
from dataclasses import dataclass, field
from typing import Optional, Dict, List

# ── Station definitions ──
STATIONS = [
    "INTAKE",
    "CLASSIFIER",
    "ROUTING_FORGE",
    "AGENT_ASSEMBLY",
    "SYNTHESIS",
    "QA_GATE",
    "SHIPPING",
]

STATION_COLORS = {
    "INTAKE":        "#4DA3FF",   # blue    — intake dock
    "CLASSIFIER":    "#a78bfa",   # purple  — domain analysis
    "ROUTING_FORGE": "#F97316",   # orange  — physics routing
    "AGENT_ASSEMBLY":"#10b981",   # green   — agent responses
    "SYNTHESIS":     "#fbbf24",   # yellow  — sovereign synthesis
    "QA_GATE":       "#ef4444",   # red     — quality gate
    "SHIPPING":      "#00FF41",   # matrix  — output shipped
}

STATION_ICONS = {
    "INTAKE":        "📥",
    "CLASSIFIER":    "🔬",
    "ROUTING_FORGE": "⚙️",
    "AGENT_ASSEMBLY":"🤖",
    "SYNTHESIS":     "🧬",
    "QA_GATE":       "🛡️",
    "SHIPPING":      "📤",
}


@dataclass
class WorkOrder:
    """A single thought moving through the factory."""
    id: str
    query: str
    created_at: float = field(default_factory=time.time)
    current_station: str = "INTAKE"
    station_index: int = 0

    # Per-station timing and output
    station_times: Dict[str, float]  = field(default_factory=dict)   # station → ms spent
    station_outputs: Dict[str, str]  = field(default_factory=dict)   # station → brief output
    station_entered: Dict[str, float]= field(default_factory=dict)   # station → entry timestamp

    # Final metadata
    mode: str = "ZEN"
    agents_answered: bool = False
    used_phi: bool = False
    energy: int = 0
    resonance: float = 0.0
    voxel_pos: tuple = (16, 5, 16)
    response_preview: str = ""
    completed: bool = False
    total_ms: float = 0.0

    # Quality score 0-100
    quality: int = 0

    def enter_station(self, station: str):
        self.current_station = station
        self.station_index = STATIONS.index(station) if station in STATIONS else 0
        self.station_entered[station] = time.perf_counter()

    def leave_station(self, station: str, output: str = ""):
        if station in self.station_entered:
            elapsed_ms = (time.perf_counter() - self.station_entered[station]) * 1000
            self.station_times[station] = round(elapsed_ms, 1)
        if output:
            self.station_outputs[station] = output[:120]

    def finish(self, response: str, used_phi: bool):
        self.completed = True
        self.used_phi = used_phi
        self.response_preview = response[:100]
        self.total_ms = round((time.perf_counter() - self.created_at) * 1000, 1)

        # Quality score: sovereign answer = higher, phi needed = lower, fast = bonus
        base = 100
        if used_phi:
            base -= 25    # lost points for needing phi
        if not self.agents_answered:
            base -= 20    # lost points if no agent claimed domain
        if self.total_ms > 3000:
            base -= 10    # slow response penalty
        elif self.total_ms < 500:
            base += 5     # speed bonus
        self.quality = max(0, min(100, base))

    def to_dict(self) -> dict:
        return {
            "id":              self.id,
            "query":           self.query[:80],
            "mode":            self.mode,
            "current_station": self.current_station,
            "station_index":   self.station_index,
            "total_stations":  len(STATIONS),
            "progress_pct":    round((self.station_index / max(1, len(STATIONS) - 1)) * 100),
            "station_times":   self.station_times,
            "station_outputs": self.station_outputs,
            "energy":          self.energy,
            "resonance":       self.resonance,
            "voxel_pos":       list(self.voxel_pos),
            "agents_answered": self.agents_answered,
            "used_phi":        self.used_phi,
            "quality":         self.quality,
            "response_preview":self.response_preview,
            "completed":       self.completed,
            "total_ms":        self.total_ms,
            "created_at":      self.created_at,
        }


class ThoughtFactory:
    """
    The production floor. Tracks all active and recently completed work orders.
    Thread-safe. Singleton — shared across the bridge.
    """

    def __init__(self, history_size: int = 50):
        self._lock = threading.Lock()
        self._active: Dict[str, WorkOrder] = {}         # id → WorkOrder (in flight)
        self._completed: deque = deque(maxlen=history_size)  # recently done
        self._throughput_window: deque = deque(maxlen=100)   # completion timestamps
        self._total_processed = 0
        self._phi_consults = 0

    # ── Work order lifecycle ──

    def intake(self, query: str, energy: int = 0, resonance: float = 0.0) -> WorkOrder:
        """Create a new work order and place it at the INTAKE station."""
        order = WorkOrder(
            id=str(uuid.uuid4())[:8],
            query=query,
            energy=energy,
            resonance=resonance,
        )
        order.enter_station("INTAKE")
        order.station_outputs["INTAKE"] = f"energy={energy} CEU, resonance={resonance:.2f}"
        with self._lock:
            self._active[order.id] = order
        return order

    def advance(self, order: WorkOrder, station: str, output: str = ""):
        """Move a work order to the next station."""
        with self._lock:
            if order.id not in self._active:
                return
            prev = order.current_station
            order.leave_station(prev, output)
            order.enter_station(station)

    def complete(self, order: WorkOrder, response: str, used_phi: bool,
                 agents_answered: bool, mode: str, voxel_pos: tuple):
        """Finalize a work order and move it to completed history."""
        with self._lock:
            if order.id not in self._active:
                return
            order.leave_station(order.current_station, response[:80])
            order.agents_answered = agents_answered
            order.mode = mode
            order.voxel_pos = voxel_pos
            order.finish(response, used_phi)
            del self._active[order.id]
            self._completed.appendleft(order)
            self._throughput_window.append(time.time())
            self._total_processed += 1
            if used_phi:
                self._phi_consults += 1

    def get_order(self, order_id: str) -> Optional[WorkOrder]:
        with self._lock:
            return self._active.get(order_id)

    # ── State for dashboard ──

    def floor_state(self) -> dict:
        """Complete factory floor state for the dashboard."""
        with self._lock:
            active_list = [o.to_dict() for o in self._active.values()]
            completed_list = [o.to_dict() for o in self._completed]

        # Throughput: completions in last 60s
        now = time.time()
        recent = sum(1 for t in self._throughput_window if now - t < 60)

        # Station load: how many active orders at each station
        station_load = {s: 0 for s in STATIONS}
        for o in active_list:
            cs = o.get("current_station", "INTAKE")
            if cs in station_load:
                station_load[cs] += 1

        # Average quality of last 10 completed
        recent_completed = list(self._completed)[:10]
        avg_quality = (
            sum(o.quality for o in recent_completed) / len(recent_completed)
            if recent_completed else 0
        )

        # Phi rate
        phi_rate = round(
            (self._phi_consults / max(1, self._total_processed)) * 100, 1
        )

        return {
            "stations":        STATIONS,
            "station_colors":  STATION_COLORS,
            "station_icons":   STATION_ICONS,
            "station_load":    station_load,
            "active":          active_list,
            "completed":       completed_list[:20],  # last 20
            "throughput_rpm":  recent,
            "total_processed": self._total_processed,
            "phi_rate_pct":    phi_rate,
            "avg_quality":     round(avg_quality, 1),
            "active_count":    len(active_list),
            "sovereign_rate":  round(100 - phi_rate, 1),
        }


# ── Singleton ──
factory = ThoughtFactory()
