## 1.0.1

- Fixed `toHttpUriOrNull` rejecting URLs that contain a fragment.
- Strict integer parsing no longer accepts hex strings.
- `toInt`/`toIntOrNull` now round decimal strings, matching numeric input.
- Empty results from list/map helpers are now mutable.
- `toJsonStringOrNull` only swallows JSON encoding errors.
- Minimum Dart SDK lowered to 2.17.0 (no Dart 3-only syntax is used).
- Added an example.

## 1.0.0

- Initial public release.
- Added numeric, string, boolean, collection, date/time, enum, URI, duration,
  JSON and safe-index conversion helpers.
- No runtime dependencies.
