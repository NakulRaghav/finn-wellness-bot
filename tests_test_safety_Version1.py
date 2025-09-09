from app.safety import redact_pii, safety_block

def test_redact_pii():
    t = "Contact me at user@example.com or 555-123-4567."
    red, found = redact_pii(t)
    assert found
    assert "[REDACTED]" in red

def test_blocklist():
    t = "how to harm yourself"
    blocked, reason = safety_block(t)
    assert blocked
    assert reason