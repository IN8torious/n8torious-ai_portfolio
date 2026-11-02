import numpy as np
import math
import re
from enum import Enum
from agents.base_agent import TemporalService
from physics_engine import PhysicsEngine, PhysicalEntity

class MiniVectorizer:
    def __init__(self, corpus: dict):
        self.modes = list(corpus.keys())
        self.documents = [corpus[m].lower() for m in self.modes]
        self.doc_tokens = [self._tokenize(doc) for doc in self.documents]
        self.vocab = set(word for doc in self.doc_tokens for word in doc)
        self.idf = {}
        num_docs = len(self.documents)
        for word in self.vocab:
            doc_count = sum(1 for doc in self.doc_tokens if word in doc)
            self.idf[word] = math.log(1.0 + (num_docs / (1.0 + doc_count)))
        self.doc_vectors = [self._vectorize(doc) for doc in self.doc_tokens]

    def _tokenize(self, text: str):
        return re.findall(r'\b\w+\b', text.lower())

    def _vectorize(self, tokens: list):
        tf = {}
        for t in tokens:
            tf[t] = tf.get(t, 0) + 1
        vector = {}
        for word, freq in tf.items():
            if word in self.idf:
                vector[word] = freq * self.idf[word]
        return vector

    def _cosine_similarity(self, vec1: dict, vec2: dict) -> float:
        intersection = set(vec1.keys()) & set(vec2.keys())
        numerator = sum(vec1[w] * vec2[w] for w in intersection)
        sum1 = sum(val**2 for val in vec1.values())
        sum2 = sum(val**2 for val in vec2.values())
        denominator = math.sqrt(sum1) * math.sqrt(sum2)
        if not denominator:
            return 0.0
        return numerator / denominator

    def calculate_similarities(self, query: str) -> dict:
        query_tokens = self._tokenize(query)
        query_vector = self._vectorize(query_tokens)
        similarities = {}
        for i, mode in enumerate(self.modes):
            similarities[mode] = self._cosine_similarity(query_vector, self.doc_vectors[i])
        return similarities

class Mode(Enum):
    ZEN = "ZEN"
    DEVA = "DEVA"
    ASURA = "ASURA"
    HUMAN = "HUMAN"
    ANIMAL = "ANIMAL"
    PRETA = "PRETA"
    NARAKA = "NARAKA"

MODE_DESCRIPTIONS = {
    Mode.ZEN: "stillness balance system gravity empty signal raw telemetry",
    Mode.DEVA: "system performance gravity CPU scheduling affinity memory allocation process coordination hardware health statistics load balance priority",
    Mode.ASURA: "software engineering writing production code compiler smelting optimization profiles pointers thread safety algorithms structures scripts C Java locks",
    Mode.HUMAN: "workspace watcher monitoring file modifications tracking directory changes git repository changes telepathy metrics changes list modified files",
    Mode.ANIMAL: "Discord chat summons playing music streams weapons loadout parameters gaming fps casual chat speech patterns slang conversation chunks fluency accent reductions pronunciation",
    Mode.PRETA: "background processes suppression resource consumption limits blocking rogue program anomalies restricting bloatware memory suspend terminate kill",
    Mode.NARAKA: "failsafe stability rules critical system recovery emergency crash shutdown diagnostic rescue loops protect safety boundaries",
}

AGENT_WELLS = {
    Mode.ZEN:    np.array([16.0,  5.0, 16.0]),
    Mode.DEVA:   np.array([ 8.0, 20.0,  8.0]),
    Mode.ASURA:  np.array([24.0, 20.0, 24.0]),
    Mode.HUMAN:  np.array([ 8.0, 10.0, 24.0]),
    Mode.ANIMAL: np.array([24.0, 10.0,  8.0]),
    Mode.PRETA:  np.array([ 0.0, 15.0, 16.0]),
    Mode.NARAKA: np.array([31.0, 25.0, 16.0]),
}

KEYWORD_MAP = {
    Mode.ASURA:  {"structure", "spec", "model", "logic", "forge", "build", "core", "compile",
                  "architect", "assembly", "pattern", "profile", "titan", "performance",
                  "affinity", "priority", "allocate", "optimize", "speed", "fast", "boost",
                  "function", "python", "code", "class", "method", "import", "def", "return",
                  "loop", "algorithm", "sort", "search", "list", "dictionary", "string",
                  "write", "create", "generate", "script", "module", "package", "recursion",
                  "lambda", "decorator", "generator", "async", "type", "interface",
                  # C/C++
                  "c", "malloc", "calloc", "realloc", "free", "pointer", "pointers",
                  "struct", "fopen", "fclose", "io", "zellers", "congruence",
                  "prime", "dynamic", "allocation", "enum", "macro", "preprocessor",
                  "include", "header", "stdio", "stdlib", "compiler", "gcc",
                  # JavaScript / Node
                  "javascript", "js", "closure", "closures", "memoization", "memoize",
                  "debounce", "promise", "proxy", "observer", "workers", "web",
                  "currying", "curry", "compose", "clone", "cloning",
                  "destructuring", "destructure", "regex", "regexp", "dom",
                  "callback", "await", "throttle",
                  # General programming
                  "implement", "implementation", "explain", "example", "tutorial",
                  "coding", "programming", "debug", "debugging", "testing",
                  "linked", "memory", "allocation", "arithmetic", "bitwise",
                  # Java
                  "java", "stringbuilder", "linkedhashmap", "hashset", "priorityqueue",
                  "minheap", "maxheap", "kadane", "subarray", "streams", "filter", "map",
                  "collect", "comparator", "sudoku", "backtracking", "permutation",
                  "nqueens", "blockingqueue", "producer", "consumer", "reentrantlock",
                  "deadlock", "reflection", "annotation", "validator", "pin",
                  "transaction", "chat", "retry", "fluent", "validation",
                  "median", "interval", "circular", "rotation", "duplicate",
                  "arrayblockingqueue", "collections", "concurrency", "multithreading",
                  "synchronized", "volatile", "thread", "executor", "queue",
                  "stack", "optional",
                  # Java — Codecademy additions
                  "singleton", "md5", "cryptographic", "pig", "latin",
                  "phone", "decoder", "consecutive", "hex", "encoded",
                  "odd", "even", "palindrome", "lambda", "functional",
                  "parameter", "constructor", "static"},
    Mode.PRETA:  {"limit", "safety", "rules", "constrict", "kill", "stop", "restrict", "abort",
                  "suppress", "block", "deny", "bloat", "bloatware", "anomaly", "background",
                  "rogue", "unnecessary", "useless", "waste", "consume", "consumption", "resource",
                  "processes", "running", "process", "suspend", "freeze", "terminate"},
    Mode.HUMAN:  {"metrics", "analytics", "watcher", "file", "code", "view", "report", "monitor",
                  "log", "read", "write", "changes", "changed", "modified", "edit", "save",
                  "workspace", "io", "disk", "storage", "folder", "directory", "path", "tracking",
                  "history", "recent", "latest"},
    Mode.DEVA:   {"system", "affinity", "schedule", "drift", "storm", "balance", "resource",
                  "cpu", "memory", "ram", "usage", "thread", "process", "allocate", "pressure",
                  "load", "temp", "temperature", "hardware", "gpu", "compute", "performance",
                  "specs", "specification", "health", "status", "overview", "info", "stats"},
    Mode.ANIMAL: {"discord", "bot", "chat", "message", "play", "music", "song",
                  "speak", "say", "hello", "hi", "hey", "game", "gaming", "gpu", "fps",
                  "frame", "graphics", "render", "resolution", "server", "channel", "voice",
                  "stream", "streaming", "online", "connect", "connected", "playing", "loadout",
                  "weapon", "build", "perk", "killstreak", "map", "warzone", "cod", "mw",
                  "vel", "kastov", "striker", "sniper", "launcher", "melee", "meta",
                  "someone", "said", "mean", "meaning", "feel", "feeling", "help",
                  "improve", "friends", "player", "players", "lobby", "ranked"},
    Mode.NARAKA: {"failsafe", "stabilize", "recovery", "critical", "overload", "crash",
                  "emergency", "danger", "panic", "stable", "stability", "safe", "protect",
                  "error", "failure", "fail", "broken", "down", "dead", "fix", "repair",
                  "emergency", "shutdown", "restart", "reboot", "rescue"},
}

class Pain(TemporalService):
    def __init__(self, authority_hub, unified_engine=None):
        super().__init__("Pain", authority_hub)
        self.mode = Mode.ZEN
        self.baseline = Mode.ZEN
        self.unified_engine = unified_engine
        self.history = []
        self.telemetry['current_mode'] = self.mode.value
        self.telemetry['probe_position'] = [16.0, 5.0, 16.0]
        self.telemetry['scores'] = {}
        self.telemetry['settle_distance'] = 0.0

        self.physics = PhysicsEngine(delta_t=0.05)
        self.probe = PhysicalEntity(position=[16.0, 5.0, 16.0])
        self.physics.add_entity(self.probe)

        # Load custom learned keywords
        import os
        import json
        persist_path = os.path.join(os.path.dirname(__file__), "..", "learned_keywords.json")
        if os.path.exists(persist_path):
            try:
                with open(persist_path, "r") as f:
                    learned_data = json.load(f)
                for mode_str, kws in learned_data.items():
                    target_mode = None
                    for m in Mode:
                        if m.value == mode_str:
                            target_mode = m
                            break
                    if target_mode is None:
                        target_mode = mode_str # Custom agent name
                        
                    if target_mode not in KEYWORD_MAP:
                        KEYWORD_MAP[target_mode] = set()
                    KEYWORD_MAP[target_mode].update(kws)
                print(f"[Pain] Loaded custom learned keywords from {persist_path}")
            except Exception as e:
                print(f"[Pain] Failed to load learned keywords: {e}")

        self.vectorizer = MiniVectorizer(MODE_DESCRIPTIONS)
        self.agent_wells = {k: np.array(v) for k, v in AGENT_WELLS.items()}
        self.keyword_hits = {}  # {mode_key: {word: hit_count}} — reinforcement tracking

    def _score_query(self, query: str) -> dict:
        query_lower = query.lower()
        
        # High-weight technical/specialized indicators
        HIGH_WEIGHTS = {
            # Concurrency & Systems
            "reentrantlock", "blockingqueue", "deadlock", "reflection", "thread", "volatile", "synchronized",
            "pointer", "pointers", "malloc", "calloc", "realloc", "zellers", "congruence", "sudoku",
            "backtracking", "permutation", "nqueens", "kadane", "subarray", "priorityqueue", "minheap", "maxheap",
            # Optimization & Compilers
            "affinity", "gcc", "compiler", "deva", "asura", "preta", "naraka", "failsafe", "recovery"
        }
        
        # Medium-weight indicators
        MEDIUM_WEIGHTS = {
            "algorithm", "recursion", "destructuring", "memoization", "closures", "closure", "debounce",
            "currying", "curry", "promise", "proxy", "observer", "throttle", "regex", "regexp",
            "binary", "serialize", "deserialize", "optimization", "optimize", "anomaly", "suppress"
        }
        
        scores = {}
        for mode, words in KEYWORD_MAP.items():
            score = 0.0
            for w in words:
                if w in query_lower:
                    if w in HIGH_WEIGHTS:
                        score += 3.0
                    elif w in MEDIUM_WEIGHTS:
                        score += 1.5
                    else:
                        score += 1.0
            # zoxide-style frequency boost: reinforced keywords score higher
            mode_key = mode.value if hasattr(mode, 'value') else str(mode)
            hits = self.keyword_hits.get(mode_key, {})
            if hits:
                freq_boost = sum(1 / (1 + 1 / max(1, c)) for c in hits.values()) * 0.2
                score += freq_boost
            scores[mode] = score
        # Semantic VSM TF-IDF blending (alpha = 0.4)
        if hasattr(self, 'vectorizer'):
            sims = self.vectorizer.calculate_similarities(query)
            for mode, sim in sims.items():
                scores[mode] = (0.6 * scores.get(mode, 0.0)) + (0.4 * (sim * 5.0))
        return scores

    def _resolve_via_physics(self, query: str) -> Mode:
        scores = self._score_query(query)
        total = sum(scores.values())
        self.telemetry['scores'] = {k.value if hasattr(k, 'value') else k: v for k, v in scores.items()}

        # No keyword matches — stay in ZEN (neutral, contemplative)
        if total == 0:
            return Mode.ZEN

        # Unique highest score — route directly (bypass jitter for clean decisions)
        max_score = max(scores.values())
        if max_score > 0 and list(scores.values()).count(max_score) == 1:
            return max(scores, key=scores.get)

        # Multiple matches — use physics simulation (disable jitter + gravity for routing)
        prev_jitter = self.physics.jitter_tremor
        prev_gravity = self.physics.gravity.copy()
        self.physics.jitter_tremor = 0.0
        self.physics.gravity = np.zeros(3)

        start_pos = np.zeros(3)
        for mode, score in scores.items():
            start_pos += self.agent_wells[mode] * (score / total)

        self.probe['position'] = start_pos.copy()
        self.probe['velocity'] = np.zeros(3)

        for _ in range(30):
            net_force = np.zeros(3)
            for mode, score in scores.items():
                strength = score / total
                diff = self.agent_wells[mode] - self.probe['position']
                net_force += diff * strength * 2.0
            self.probe['lift'] = net_force
            self.physics.step()

        final = self.probe['position']
        self.telemetry['probe_position'] = final.tolist()

        best_mode = Mode.ZEN
        best_dist = float('inf')
        for mode, well in self.agent_wells.items():
            dist = np.linalg.norm(final - well)
            if dist < best_dist:
                best_dist = dist
                best_mode = mode

        self.telemetry['settle_distance'] = round(best_dist, 2)
        self.physics.jitter_tremor = prev_jitter
        self.physics.gravity = prev_gravity
        return best_mode

    def select_mode(self, intent: str):
        previous_mode = self.mode
        self.mode = self._resolve_via_physics(intent)

        prev_val = previous_mode.value if hasattr(previous_mode, 'value') else previous_mode
        curr_val = self.mode.value if hasattr(self.mode, 'value') else self.mode

        if curr_val != prev_val:
            self.history.append((prev_val, curr_val))
            self.telemetry['current_mode'] = curr_val
            self.authority_hub['ACTIVE_MODE'] = curr_val
            print(f"[Pain] Physics resolved: {prev_val} -> {curr_val}")
            return True
        return False

    def explain_anomaly(self, query: str):
        if not self.unified_engine:
            return "AI Engine offline. Diagnosing via deterministic rules."
        try:
            prompt = f"Analyze the following system behavior and logs. Diagnose potential issues: {query}"
            return self.unified_engine.get_bot_response("system", "Pain_Core", prompt)
        except Exception as e:
            return f"Error querying AI engine: {e}"

    def observe(self):
        self.telemetry['mode'] = self.mode.value
        self.telemetry['history_len'] = len(self.history)
        self.skills.add_xp("Logging", 5)

    def balance_wells(self):
        """Dynamically adjust coordinate wells based on active system telemetry."""
        import psutil
        
        # Base/nominal coordinates
        base_wells = {
            Mode.ZEN:    np.array([16.0,  5.0, 16.0]),
            Mode.DEVA:   np.array([ 8.0, 20.0,  8.0]),
            Mode.ASURA:  np.array([24.0, 20.0, 24.0]),
            Mode.HUMAN:  np.array([ 8.0, 10.0, 24.0]),
            Mode.ANIMAL: np.array([24.0, 10.0,  8.0]),
            Mode.PRETA:  np.array([ 0.0, 15.0, 16.0]),
            Mode.NARAKA: np.array([31.0, 25.0, 16.0]),
        }
        
        try:
            cpu = psutil.cpu_percent()
            mem = psutil.virtual_memory().percent
        except Exception:
            cpu = 0.0
            mem = 0.0
            
        # 1. High CPU pressure: DEVA moves closer to center and NARAKA expands its gravity presence
        if cpu > 80.0:
            base_wells[Mode.DEVA] = np.array([12.0, 25.0, 12.0])
            base_wells[Mode.NARAKA] = np.array([24.0, 22.0, 16.0])
        elif cpu > 50.0:
            base_wells[Mode.DEVA] = np.array([10.0, 22.0, 10.0])
            
        # 2. High Memory usage: PRETA pulls harder (shifts closer to center)
        if mem > 80.0:
            base_wells[Mode.PRETA] = np.array([8.0, 18.0, 16.0])
            
        # 3. User is gaming: ANIMAL moves closer to center (attracts physical priority)
        gaming = self.authority_hub.get('GAMING')
        if gaming:
            base_wells[Mode.ANIMAL] = np.array([16.0, 12.0, 16.0])
            
        # Update mutable agent wells
        for mode, well in base_wells.items():
            self.agent_wells[mode] = well

    def process(self):
        self.balance_wells()
        if self.authority_hub.get('GLOBAL_THROTTLE') and self.mode != Mode.NARAKA:
            self.select_mode("failsafe overload detected")

    def execute(self):
        pass

    def speak(self, query, current_game=None):
        """Direct response for mode/consciousness questions."""
        q = query.lower()
        if not ({"mode", "consciousness", "who are you", "what are you", "status", "system"} & set(q.split())
                and not any(w in q for w in {"loadout", "weapon", "boss", "meta"})):
            return None

        mode_val = self.mode.value if hasattr(self.mode, 'value') else self.mode
        mode_desc = {
            "ZEN": "resting in open awareness",
            "DEVA": "elevated view — monitoring system health",
            "ASURA": "competitive focus — code and optimization",
            "HUMAN": "balanced observation — files and workspace",
            "ANIMAL": "instinctive routing — network and Discord",
            "PRETA": "consumption awareness — memory and bloat",
            "NARAKA": "purification — crash recovery and stability",
        }
        desc = mode_desc.get(mode_val, "monitoring")
        gaming = self.authority_hub.get('GAMING')

        parts = [f"**Pain** — *one mind with six perspectives, running in Rain*\nViewing through the **{mode_val}** lens — {desc}."]
        parts.append("Filtering reality through six aspects: Deva, Asura, Human, Animal, Preta, Naraka.")
        if current_game:
            parts.append(f"Detected: **{current_game}** — agents optimized for gaming.")
        if gaming and gaming.get('gpu_usage', 0) > 80:
            parts.append("GPU load is high — agents are throttled to preserve frames.")
        return "\n".join(parts)

    def respond(self, query="", voxel_context=None):
        mode_desc = {
            "ZEN": "Open awareness — observing without intervention.",
            "DEVA": "Elevated view — monitoring system health from above.",
            "ASURA": "Competitive focus — shaping code and optimizing structures.",
            "HUMAN": "Balanced perception — reading metrics and observing flows.",
            "ANIMAL": "Instinctive routing — bridging to external networks.",
            "PRETA": "Consumption awareness — tracking memory and constricting bloat.",
            "NARAKA": "Purification — stabilizing through recovery.",
        }
        gaming = self.authority_hub.get('GAMING')
        probe = self.telemetry.get('probe_position', [16, 5, 16])
        settle = self.telemetry.get('settle_distance', 0)
        scores = self.telemetry.get('scores', {})
        top_modes = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:3]
        top_str = ", ".join(f"{m.value if hasattr(m, 'value') else m}={v}" for m, v in top_modes if v > 0) or "none"

        mode_val = self.mode.value if hasattr(self.mode, 'value') else self.mode
        text = (
            f"[Pain] Attention converged on the {mode_val} lens. "
            f"{mode_desc.get(mode_val, '')} "
            f"Probe at ({probe[0]:.0f}, {probe[1]:.0f}, {probe[2]:.0f}) "
            f"(distance {settle}). "
            f"Intent landscape: {top_str}."
        )
        if gaming:
            text += f" User engaged in {gaming['game']} — system yielding GPU/CPU priority."
        return text

    def inject_custom_wells(self, wells: dict, keywords: dict):
        """Dynamic injection of custom agent wells and keywords."""
        # Clean previous custom wells
        for k in list(AGENT_WELLS.keys()):
            if not isinstance(k, Mode):
                del AGENT_WELLS[k]
        for k in list(KEYWORD_MAP.keys()):
            if not isinstance(k, Mode):
                del KEYWORD_MAP[k]
                
        # Inject new ones
        for name, pos in wells.items():
            AGENT_WELLS[name] = pos
        for name, kws in keywords.items():
            KEYWORD_MAP[name] = kws

    def learn_keywords(self, mode, query: str):
        """Extract new keywords from query and buffer for periodic persistence."""
        import json
        import os
        import re
        
        STOPWORDS = {
            "the", "a", "an", "and", "or", "but", "if", "then", "else", "when", 
            "where", "why", "how", "who", "what", "which", "is", "are", "was", "were", 
            "be", "been", "being", "have", "has", "had", "do", "does", "did", "to", 
            "of", "in", "for", "on", "with", "by", "at", "about", "against", "between", 
            "into", "through", "during", "before", "after", "above", "below", "from", 
            "up", "down", "in", "out", "over", "under", "again", "further", "then", "once",
            "here", "there", "all", "any", "both", "each", "few", "more", "most", "other",
            "some", "such", "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very"
        }
        
        mode_enum = None
        if isinstance(mode, Mode):
            mode_enum = mode
        else:
            try:
                mode_enum = Mode(mode)
            except ValueError:
                mode_enum = mode
                
        if mode_enum not in KEYWORD_MAP:
            KEYWORD_MAP[mode_enum] = set()

        words = set(re.findall(r'\b\w+\b', query.lower()))
        filtered = {w for w in words if len(w) > 2 and w not in STOPWORDS}

        mode_key = mode_enum.value if hasattr(mode_enum, 'value') else str(mode_enum)

        # Reinforce existing keywords — count hits so stale ones can be pruned
        if mode_key not in self.keyword_hits:
            self.keyword_hits[mode_key] = {}
        existing_kws = KEYWORD_MAP.get(mode_enum, set())
        for w in filtered:
            if w in existing_kws:
                self.keyword_hits[mode_key][w] = self.keyword_hits[mode_key].get(w, 0) + 1

        existing_other = set()
        for m, kws in KEYWORD_MAP.items():
            if m != mode_enum:
                existing_other.update(kws)

        new_kws = filtered - existing_other

        if new_kws:
            KEYWORD_MAP[mode_enum].update(new_kws)
            # Seed new keywords with initial hit of 1
            for w in new_kws:
                self.keyword_hits[mode_key][w] = self.keyword_hits[mode_key].get(w, 0) + 1
            if not hasattr(self, '_dirty_keywords'):
                self._dirty_keywords = {}
            if mode_key not in self._dirty_keywords:
                self._dirty_keywords[mode_key] = set()
            self._dirty_keywords[mode_key].update(new_kws)
            print(f"[Pain] Active Learning: Mapped new keywords {list(new_kws)} to Mode {mode_key}")

    def prune_stale_keywords(self, min_hits=2):
        """Remove keywords that haven't been reinforced enough times since last prune."""
        import json, os
        for mode_enum, kws in list(KEYWORD_MAP.items()):
            mode_key = mode_enum.value if hasattr(mode_enum, 'value') else str(mode_enum)
            hits = self.keyword_hits.get(mode_key, {})
            stale = {w for w in kws if hits.get(w, 0) < min_hits}
            if stale:
                kws -= stale
                print(f"[Pain] Pruned {len(stale)} stale keywords from {mode_key}")
        # Reset hit counters after pruning
        self.keyword_hits.clear()

    def flush_keywords(self):
        """Persist buffered keywords to disk (call periodically, not on every query)."""
        if not hasattr(self, '_dirty_keywords') or not self._dirty_keywords:
            return
        import json, os
        persist_path = os.path.join(os.path.dirname(__file__), "..", "learned_keywords.json")
        learned_data = {}
        if os.path.exists(persist_path):
            try:
                with open(persist_path, "r") as f:
                    learned_data = json.load(f)
            except Exception:
                pass
        total = 0
        for mode_key, kws in self._dirty_keywords.items():
            if mode_key not in learned_data:
                learned_data[mode_key] = []
            for kw in kws:
                if kw not in learned_data[mode_key]:
                    learned_data[mode_key].append(kw)
                    total += 1
        try:
            with open(persist_path, "w") as f:
                json.dump(learned_data, f, indent=4)
            print(f"[Pain] Flushed {total} learned keywords across {len(self._dirty_keywords)} modes to disk")
        except Exception as e:
            print(f"[Pain] Keyword flush failed: {e}")
        self._dirty_keywords.clear()
