
# Rule: Security

> Hard limits — always enforced, even when RAG is unavailable.

## Never violate

* Never hardcode credentials, API keys, tokens, or passwords in code
* Never commit `.env` files with real values
* Never log sensitive data (tokens, passwords, PII)
* Never use `eval()` or dynamic code execution with user input
* Never disable CSRF protection
* Never expose stack traces to the client in production
* Never expose internal numeric IDs in public APIs — use UUIDs or slugs
* Never use raw SQL string concatenation — always parameterized queries
