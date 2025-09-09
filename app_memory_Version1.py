import os
import sqlite3
from typing import List, Tuple

class MemoryStore:
    def __init__(self, db_path: str = ".data/state.db"):
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self._init()

    def _init(self):
        cur = self.conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                user_id TEXT,
                session_id TEXT,
                role TEXT,
                content TEXT,
                ts DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        self.conn.commit()

    def add(self, user_id: str, session_id: str, role: str, content: str):
        cur = self.conn.cursor()
        cur.execute("INSERT INTO messages (user_id, session_id, role, content) VALUES (?, ?, ?, ?)",
                    (user_id, session_id, role, content))
        self.conn.commit()

    def recent(self, user_id: str, session_id: str, limit: int = 10) -> List[Tuple[str, str]]:
        cur = self.conn.cursor()
        cur.execute("""
            SELECT role, content FROM messages
            WHERE user_id=? AND session_id=?
            ORDER BY ts DESC LIMIT ?
        """, (user_id, session_id, limit))
        rows = cur.fetchall()
        # return newest -> oldest
        return rows