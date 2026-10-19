# flutter_type_parser

A dependency-free Dart utility for parsing inconsistent API values into typed Dart values.

## Features

- Nullable and strict numeric parsing
- String and boolean conversion
- Safe map and list conversion
- ISO 8601 dates and explicit Unix timestamp conversion
- Enum parsing
- URI and HTTP(S) URL parsing
- Duration and millisecond conversion
- JSON encode/decode helpers
- Safe list-index access

## Requirements

- Dart SDK `>=2.17.0 <4.0.0`
- No runtime dependencies

## Install

After publishing to pub.dev, add this to your app's `pubspec.yaml`:

```yaml
dependencies:
  flutter_type_parser: ^1.0.1
```

Then run:

```bash
flutter pub get
```

## Import

```dart
import 'package:flutter_type_parser/flutter_type_parser.dart';
```

## Examples

```dart
final id = FlutterTypeParser.toIntStrictOrNull(json['id']);
final enabled = FlutterTypeParser.toBoolOrNull(json['is_enabled']);
final menu = FlutterTypeParser.toMapOrNull(json['menu']);
final extras = FlutterTypeParser.toMapList(json['extras']);
final createdAt = FlutterTypeParser.toDateTimeOrNull(json['created_at']);
final imageUri = FlutterTypeParser.toHttpUriOrNull(json['image_url']);
final decoded = FlutterTypeParser.decodeJsonOrNull(json['metadata']);
```

## API behavior notes

- `toInt` rounds numeric decimals; strict nullable parsing rejects fractional values.
- `toBool` defaults unknown values to `false`; `toBoolOrNull` preserves invalidity as `null`.
- Unix timestamp helpers require an explicit unit: seconds or milliseconds.
- `toDurationOrNull` interprets numeric values as milliseconds.
- `toHttpUriOrNull` validates the URL scheme and structure but does not check network reachability.
- `toDateTime` uses the UTC epoch if parsing fails and no fallback is supplied. Prefer `toDateTimeOrNull` for business data.

## Development

```bash
dart pub get
dart format .
dart analyze
dart test
dart pub publish --dry-run
```

Before publishing, replace the placeholder repository and issue-tracker URLs in `pubspec.yaml` with your real repository URLs.

## License

See `LICENSE`.
# flutter_type_parser
