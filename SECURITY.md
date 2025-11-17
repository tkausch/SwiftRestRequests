# Security Policy

## Supported Versions

SwiftRestRequests follows semantic versioning. We provide security updates for the following versions:

| Version | Supported          | Status                    |
| ------- | ------------------ | ------------------------- |
| 1.7.x   | :white_check_mark: | Upcoming release          |
| 1.6.x   | :white_check_mark: | Current stable release    |
| 1.5.x   | :white_check_mark: | Security fixes only       |
| < 1.5   | :x:                | No longer supported       |

We strongly recommend always using the latest stable release to benefit from security patches, bug fixes, and new features.

## Security Considerations

SwiftRestRequests is built on Foundation's `URLSession` and inherits its security model. When using this library, please be aware of:

### Transport Security

- **App Transport Security (ATS)**: On Apple platforms, ATS is enforced by default. Ensure your backend endpoints use HTTPS with valid TLS certificates.
- **Certificate Pinning**: For additional security, use the built-in `CertificateCAPinning` or `PublicKeyServerPinning` classes to pin specific certificates or public keys.
- **Custom URLSession Configuration**: If you provide your own `URLSessionConfiguration`, ensure it maintains appropriate security settings.

### Sensitive Data

- **Logging**: The library includes a `LogNetworkInterceptor` that can log request/response data. **Never enable verbose network logging in production builds** as it may expose sensitive information (tokens, API keys, personal data).
- **Authentication**: Use the provided `AuthorizerInterceptor` and `URLRequestAuthorizer` protocols for handling authentication. Avoid hardcoding credentials in your code.
- **Cookies**: Cookie storage is managed by `HTTPCookieStorage`. Be mindful of sensitive data stored in cookies and configure cookie policies appropriately.

### Best Practices

1. **Keep Dependencies Updated**: Regularly update SwiftRestRequests and its dependency (`swift-log`) to receive security patches.
2. **Validate Server Responses**: The library validates HTTP status codes and MIME types, but always validate response content in your application logic.
3. **Use HTTPS**: Always communicate with servers over HTTPS in production.
4. **Review Interceptors**: Custom interceptors have access to all request/response data. Review third-party interceptors carefully before use.
5. **Error Handling**: `RestError` cases may contain sensitive information from server responses. Handle errors appropriately and avoid exposing internal error details to end users.

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue in SwiftRestRequests, please report it responsibly:

### How to Report

**Please DO NOT open a public GitHub issue for security vulnerabilities.**

Instead, please report security issues by emailing **thomas.kausch@gmx.net** with:

- A detailed description of the vulnerability
- Steps to reproduce the issue
- Potential impact and severity assessment
- Any suggested fixes or mitigations (if available)
- Your contact information for follow-up questions

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your report within **48 hours**.
- **Investigation**: We will investigate the issue and determine its validity and severity within **7 days**.
- **Updates**: You will receive regular updates on our progress at least every **14 days** until the issue is resolved.
- **Disclosure**: 
  - If the vulnerability is accepted, we will work on a fix and coordinate disclosure timing with you.
  - We aim to release security patches within **30 days** of confirmation for critical issues.
  - Once a patch is released, we will publish a security advisory crediting you (unless you prefer to remain anonymous).
  - If the vulnerability is declined (e.g., working as intended, out of scope), we will explain our reasoning.

### Scope

Security reports are welcome for:

- Authentication and authorization bypass issues
- Data exposure or leakage through logging or error messages
- TLS/certificate validation problems
- Injection vulnerabilities (if applicable)
- Dependencies with known vulnerabilities

Out of scope:

- Issues requiring physical access to a user's device
- Social engineering attacks
- Denial of service attacks against third-party servers
- Issues in third-party dependencies (please report directly to those projects)

## Security Advisories

Published security advisories will be available in the [GitHub Security Advisories](https://github.com/tkausch/SwiftRestRequests/security/advisories) section of this repository.

## Recognition

We appreciate security researchers who responsibly disclose vulnerabilities. With your permission, we will acknowledge your contribution in:

- The security advisory
- The changelog/release notes
- The project README (Hall of Fame section, if created)

Thank you for helping keep SwiftRestRequests and its users secure!