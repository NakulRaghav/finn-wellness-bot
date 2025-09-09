import os
import json
import faiss
import numpy as np
from typing import List, Tuple, Dict, Any

class DocStore:
    def __init__(self, docs_path: str):
        self.docs_path = docs_path
        self.docs: Dict[str, Dict[str, Any]] = {}
        if os.path.exists(docs_path):
            with open(docs_path, "r", encoding="utf-8") as f:
                for line in f:
                    obj = json.loads(line)
                    self.docs[obj["id"]] = obj

    def get(self, doc_id: str) -> Dict[str, Any]:
        return self.docs[doc_id]

class VectorIndex:
    def __init__(self, index_dir: str):
        self.index_dir = index_dir
        os.makedirs(index_dir, exist_ok=True)
        self.index_path = os.path.join(index_dir, "faiss.index")
        self.meta_path = os.path.join(index_dir, "meta.json")
        self.index = None
        self.ids: List[str] = []

    def load(self):
        if not (os.path.exists(self.index_path) and os.path.exists(self.meta_path)):
            raise RuntimeError("Index not found. Run ingestion.")
        self.index = faiss.read_index(self.index_path)
        with open(self.meta_path, "r", encoding="utf-8") as f:
            self.ids = json.load(f)["ids"]

    def search(self, query_vec: np.ndarray, k: int) -> List[Tuple[str, float]]:
        D, I = self.index.search(query_vec.astype("float32"), k)
        out = []
        for score, idx in zip(D[0], I[0]):
            if idx < 0 or idx >= len(self.ids):
                continue
            out.append((self.ids[idx], float(score)))
        return out