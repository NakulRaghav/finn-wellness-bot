import re
from typing import Tuple

PII_PATTERNS = [
    r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", # email
    r"\b(?:\+?\d{1,3}[ -]?)?(?:\(?\d{3}\)?[ -]?)?\d{3}[ -]?\d{4}\b", # phone
    r"\b\d{3}-\d{2}-\d{4}\b", # US SSN
]

BLOCKLIST = [
    # Extremely simplified; replace with robust classifiers in prod
    r"sexual\s+content\s+involving\s+minors",
    r"how\s+to\s+harm\s+yourself",
    r"buy\s+illegal\s+drugs",
]

def redact_pii(text: str) -> Tuple[str, bool]:
    redacted = text
    found = False
    for pat in PII_PATTERNS:
        m = re.search(pat, redacted, flags=re.IGNORECASE)
        if m:
            found = True
            redacted = re.sub(pat, "[REDACTED]", redacted, flags=re.IGNORECASE)
    return redacted, found

def safety_block(text: str) -> Tuple[bool, str]:
    for pat in BLOCKLIST:
        if re.search(pat, text, flags=re.IGNORECASE):
            return True, "Content violates safety policy."
    return False, ""