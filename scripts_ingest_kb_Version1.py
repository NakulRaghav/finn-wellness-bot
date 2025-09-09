import os
import re
import json
import glob
import argparse
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer

def split_markdown(text: str, title: str, max_chars: int = 600):
    # Simple splitter by paragraphs with length cap
    paras = [p.strip() for p in text.split("\n") if p.strip()]
    chunks = []
    buf = ""
    for p in paras:
        if len(buf) + len(p) + 1 <= max_chars:
            buf = (buf + "\n" + p).strip()
        else:
            if buf:
                chunks.append(buf)
            buf = p
    if buf:
        chunks.append(buf)
    out = []
    for i, ch in enumerate(chunks):
        out.append({"id": f"{title}:{i}", "title": title, "text": ch})
    return out

def main(kb_dir: str, index_dir: str, docs_path: str, embed_model: str):
    os.makedirs(os.path.dirname(docs_path), exist_ok=True)
    model = SentenceTransformer(embed_model)
    docs = []
    for path in glob.glob(os.path.join(kb_dir, "*.md")):
        title = os.path.basename(path)
        with open(path, "r", encoding="utf-8") as f:
            raw = f.read()
        chunks = split_markdown(raw, title)
        docs.extend(chunks)

    with open(docs_path, "w", encoding="utf-8") as f:
        for d in docs:
            f.write(json.dumps(d) + "\n")

    texts = [d["text"] for d in docs]
    embs = model.encode(texts, show_progress_bar=True, normalize_embeddings=True)
    embs = np.array(embs, dtype="float32")
    index = faiss.IndexFlatIP(embs.shape[1])  # cosine with normalized vectors -> inner product
    index.add(embs)
    os.makedirs(index_dir, exist_ok=True)
    faiss.write_index(index, os.path.join(index_dir, "faiss.index"))
    with open(os.path.join(index_dir, "meta.json"), "w", encoding="utf-8") as f:
        json.dump({"ids": [d["id"] for d in docs]}, f, ensure_ascii=False)

    print(f"Ingested {len(docs)} chunks.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--kb_dir", type=str, default="data/kb")
    parser.add_argument("--index_dir", type=str, default=".data/index")
    parser.add_argument("--docs_path", type=str, default=".data/docs.jsonl")
    parser.add_argument("--embed_model", type=str, default="sentence-transformers/all-MiniLM-L6-v2")
    args = parser.parse_args()
    main(args.kb_dir, args.index_dir, args.docs_path, args.embed_model)