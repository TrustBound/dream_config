# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | ✅ Active support  |

## What dream_config Is Responsible For

dream_config is a library that provides:
- **Environment variables** - Reading values with `get`, `get_required`, `get_int`, `get_required_int` and `get_bool`
- **`.env` files** - Reading and parsing a `.env` file and setting its variables in the environment

dream_config is **not a framework**. You build the application. You decide where your configuration comes from.

This means dream_config's security surface is small:
- `.env` parser bugs (a value read wrongly, a variable set that the file does not hold)
- Error messages that show more than the path and the reason
- Type conversion bugs in `get_int`, `get_required_int` and `get_bool`

## What You're Responsible For

Your application code handles:
- **Secrets storage** - Do not commit `.env` files with secrets
- **File permissions** - Who can read your `.env` file
- **Production configuration** - Set environment variables directly (systemd, Docker, your platform)
- **Input validation** - Beyond the type conversion that `get_int` and `get_bool` do
- **Logging** - Do not log secret values that you read

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Email: **engineering@trustbound.ai**

### What to Include

- **Type of vulnerability** (e.g., a `.env` line that sets the wrong variable)
- **Location** in dream_config's code (file/function)
- **Steps to reproduce** with minimal example
- **Impact** - What can an attacker do?
- **Proof-of-concept** if you have one

Focus on vulnerabilities in **dream_config's code**, not in your application code.

### What to Expect

1. **Acknowledgment** within 48 hours
2. **Assessment** within 7 days
3. **Fix** coordinated with you on timing
4. **Release** with security advisory
5. **Credit** in the advisory (if desired)

## Security in dream_config

### Type Safety

Gleam's type system prevents many vulnerabilities:
- ✅ No null pointer exceptions
- ✅ No buffer overflows
- ✅ Exhaustive pattern matching
- ✅ Immutable data structures

### What dream_config Doesn't Do

dream_config provides no built-in:
- ❌ Secret encryption
- ❌ Secret managers (Vault, AWS Secrets Manager, ...)
- ❌ Variable expansion (`${OTHER}` in a value)
- ❌ Validation beyond types

This is intentional. dream_config provides building blocks. You compose them.

## Dependencies

dream_config's dependencies:
- **envoy** - Reads and sets environment variables
- **Gleam stdlib** - Type-safe, battle-tested
- **BEAM/OTP** - 30+ years of production use

We monitor dependencies and update promptly for security issues.

## Questions?

- **Security questions**: engineering@trustbound.ai
- **Non-security issues**: [GitHub Issues](https://github.com/TrustBound/dream_config/issues)
- **General discussion**: [GitHub Discussions](https://github.com/TrustBound/dream/discussions)

---

**Remember:** dream_config is a library. It provides tools. You write the application. You're responsible for your application's security.
