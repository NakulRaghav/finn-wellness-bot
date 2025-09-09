import os
import json
import requests
from typing import List, Optional

try:
    from openai import OpenAI
except Exception:
    OpenAI = None

from sentence_transformers import SentenceTransformer

class Embeddings:
    def __init__(self, model_name: str):
        self.model = SentenceTransformer(model_name)

    def embed(self, texts: List[str]):
        return self.model.encode(texts, show_progress_bar=False, normalize_embeddings=True)

class LLM:
    def __init__(self, use_ollama: bool, ollama_url: str, ollama_model: str, openai_key: Optional[str], openai_model: str):
        self.use_ollama = use_ollama
        self.ollama_url = ollama_url.rstrip("/")
        self.ollama_model = ollama_model
        self.openai_model = openai_model
        self.openai_client = OpenAI(api_key=openai_key) if (openai_key and OpenAI is not None) else None

    def generate(self, prompt: str, system: Optional[str] = None, max_tokens: int = 512, temperature: float = 0.2) -> str:
        if self.use_ollama:
            data = {
                "model": self.ollama_model,
                "prompt": f"{'System: ' + system + '\n' if system else ''}{prompt}",
                "options": {"temperature": temperature, "num_predict": max_tokens}
            }
            r = requests.post(f"{self.ollama_url}/api/generate", json=data, timeout=120)
            r.raise_for_status()
            # Streamed format returns chunks; but when using /generate it returns last chunk too
            txt = ""
            for line in r.text.splitlines():
                try:
                    obj = json.loads(line)
                    if "response" in obj:
                        txt += obj["response"]
                except Exception:
                    pass
            return txt.strip()
        elif self.openai_client is not None:
            resp = self.openai_client.chat.completions.create(
                model=self.openai_model,
                messages=[
                    {"role": "system", "content": system or ""},
                    {"role": "user", "content": prompt},
                ],
                temperature=temperature,
                max_tokens=max_tokens,
            )
            return resp.choices[0].message.content.strip()
        else:
            raise RuntimeError("No LLM available. Install and run Ollama or set OPENAI_API_KEY.")