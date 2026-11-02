"""
Sovereign NL Synthesizer — zero LLM, zero API, pure Python.
BM25 retrieval + Markov chains + template grammar.
Pain's voice when phi is offline.
"""

import re
import json
import random
import math
from pathlib import Path
from collections import Counter, defaultdict

import markovify

TRAINING_DIR = Path(__file__).resolve().parent / "training"
SPAR_LOG = TRAINING_DIR / "spar_log.json"
QUERIES_FILE = TRAINING_DIR / "queries.json"
AUDIT_LOG = TRAINING_DIR / "audit_log.json"

# Response grammar templates — slots filled from knowledge base
RESPONSE_GRAMMAR = {
    "greeting": [
        "Hey! {status_line}",
        "Yo, {status_line}",
        "Hey there. {status_line}",
        "What's good? {status_line}",
    ],
    "system_status": [
        "System is running {health}. CPU at {cpu}%, memory at {mem}%. {gaming_line}",
        "Everything's {health} — CPU {cpu}%, memory {mem}%. {gaming_line}",
        "Looking {health}. CPU hovering around {cpu}%, memory at {mem}%. {gaming_line}",
    ],
    "code_response": [
        "Here's what I've got:\n\n{code_block}\n\n{explanation}",
        "Check this out:\n\n{code_block}\n\n{explanation}",
        "Here you go:\n\n{code_block}\n\n{explanation}",
    ],
    "knowledge_response": [
        "From what I know: {kb_text}",
        "Here's the data I have: {kb_text}",
        "Based on the knowledge base: {kb_text}",
    ],
    "clarify": [
        "Not entirely sure what you mean. {clarify_text}",
        "Could you clarify? {clarify_text}",
        "I want to make sure I understand. {clarify_text}",
    ],
    "error": [
        "I don't have enough information to answer that right now.",
        "That's beyond what I can determine from system telemetry alone.",
        "I'd need more context to give you a good answer on that.",
    ],
}


class BM25Retriever:
    """Simple BM25 retrieval for finding relevant training examples."""

    def __init__(self, k1=1.5, b=0.75):
        self.k1 = k1
        self.b = b
        self.documents = []
        self.doc_lengths = []
        self.avg_doc_length = 0
        self.term_freqs = defaultdict(int)
        self.doc_freqs = defaultdict(int)
        self.total_docs = 0

    def tokenize(self, text):
        return re.findall(r'\b\w+\b', text.lower())

    def add_document(self, text):
        tokens = self.tokenize(text)
        self.documents.append(text)
        self.doc_lengths.append(len(tokens))
        self.total_docs += 1
        unique_tokens = set(tokens)
        for t in unique_tokens:
            self.doc_freqs[t] += 1
        for t in tokens:
            self.term_freqs[(self.total_docs - 1, t)] += 1

        if self.total_docs > 0:
            self.avg_doc_length = sum(self.doc_lengths) / self.total_docs

    def score(self, query):
        query_tokens = self.tokenize(query)
        scores = []
        for doc_id in range(self.total_docs):
            score = 0.0
            doc_len = self.doc_lengths[doc_id]
            for token in query_tokens:
                tf = self.term_freqs.get((doc_id, token), 0)
                df = self.doc_freqs.get(token, 0)
                if df == 0:
                    continue
                idf = math.log((self.total_docs - df + 0.5) / (df + 0.5) + 1.0)
                numerator = tf * (self.k1 + 1)
                denominator = tf + self.k1 * (1 - self.b + self.b * doc_len / self.avg_doc_length)
                score += idf * (numerator / denominator)
            scores.append((score, doc_id))
        scores.sort(key=lambda x: -x[0])
        return scores

    def retrieve(self, query, top_k=3):
        results = self.score(query)
        return [self.documents[doc_id] for _, doc_id in results[:top_k] if _ > 0]


class MarkovSynthesizer:
    """Sovereign text synthesis — Markov chains + BM25 retrieval + template grammar."""

    def __init__(self):
        self.markov_model = None
        self.retriever = BM25Retriever()
        self._build_index()
        self._train_markov()

    def _build_index(self):
        """Build BM25 index from training data."""
        sources = []
        # Spar log exchanges
        if SPAR_LOG.exists():
            try:
                with open(SPAR_LOG) as f:
                    spar = json.load(f)
                    for entry in spar.get("log", []):
                        for ex in entry.get("exchanges", []):
                            text = ex.get("text", "")
                            if text and len(text) > 20:
                                sources.append(text)
            except Exception:
                pass

        # Training queries + audit responses
        for path in [QUERIES_FILE, AUDIT_LOG]:
            if path.exists():
                try:
                    with open(path) as f:
                        data = json.load(f)
                        if isinstance(data, list):
                            for item in data:
                                text = item.get("query", "") or item.get("text", "")
                                if text and len(text) > 10:
                                    sources.append(text)
                        elif isinstance(data, dict):
                            for item in data.get("flags", []):
                                text = item.get("query", "")
                                if text and len(text) > 10:
                                    sources.append(text)
                except Exception:
                    pass

        for src in sources[:2000]:
            self.retriever.add_document(src)

    def _train_markov(self):
        """Train a Markov chain model on Pain's sparring responses."""
        pain_texts = []
        if SPAR_LOG.exists():
            try:
                with open(SPAR_LOG) as f:
                    spar = json.load(f)
                    for entry in spar.get("log", []):
                        for ex in entry.get("exchanges", []):
                            if "Pain" in ex.get("speaker", "") and ex.get("speaker") != "Konan":
                                text = ex.get("text", "")
                                if text and len(text) > 30:
                                    pain_texts.append(text)
            except Exception:
                pass

        if pain_texts:
            try:
                combined = "\n".join(pain_texts)
                self.markov_model = markovify.Text(combined, state_size=2)
            except Exception:
                self.markov_model = None

    def generate(self, context="", max_chars=300):
        """Generate natural language text using Markov chains or templates."""
        # Try Markov model first
        if self.markov_model:
            try:
                result = self.markov_model.make_short_sentence(max_chars, tries=5)
                if result and len(result) > 20:
                    return result
            except Exception:
                pass

        # Fall back to BM25 retrieval
        if self.retriever.total_docs > 0:
            matches = self.retriever.retrieve(context, top_k=2)
            if matches:
                return random.choice(matches)[:max_chars]

        return None

    def synthesize_response(self, query, agent_responses=None, kb_context=None, mode=None):
        """Synthesize a complete response from available telemetry and knowledge."""
        parts = []

        # 1. Try Markov generation for conversational tone
        generated = self.generate(query, max_chars=400)
        if generated:
            parts.append(generated)

        # 2. Add agent telemetry if available
        if agent_responses:
            for name, reply in agent_responses[:3]:
                if reply and len(reply) > 10:
                    parts.append(f"[{name}] {reply}")

        # 3. Add knowledge base context if available
        if kb_context:
            kb_str = str(kb_context)
            if len(kb_str) > 20:
                parts.append(kb_str[:300])

        if not parts:
            template = random.choice(RESPONSE_GRAMMAR["error"])
            return template

        return "\n\n".join(parts)

    def format_grammar(self, template_key, **kwargs):
        """Format a grammar template with provided values."""
        templates = RESPONSE_GRAMMAR.get(template_key, [])
        if not templates:
            return None
        template = random.choice(templates)
        try:
            return template.format(**kwargs)
        except KeyError:
            return template


synthesizer = MarkovSynthesizer()
