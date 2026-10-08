# Security

Syna mobile must not contain backend secrets, private API keys, client secrets,
keystore files, provisioning profiles, or passwords in source control.

Tokens are stored with `flutter_secure_storage`. SharedPreferences is reserved
for non-sensitive preferences such as onboarding, language, and theme.

Production builds must use HTTPS, default certificate validation, release
signing, and environment values supplied by CI/CD or local dart-define files that
are not committed.

If a vulnerability is found, rotate affected credentials server-side, revoke
mobile sessions, and publish a patched build.
