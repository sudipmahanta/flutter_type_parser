import 'dart:convert';

/// Dependency-free utility for converting inconsistent API values into Dart
/// types.
///
/// Nullable methods are recommended when invalid values must be distinguished
/// from legitimate defaults. This class intentionally has no instances.
class FlutterTypeParser {
  FlutterTypeParser._();

  static final RegExp _wholeNumber = RegExp(r'^[+-]?\d+$');

  /// Parses plain decimal integers only (no hex such as `0x1A`).
  static int? _parseWhole(String text) =>
      _wholeNumber.hasMatch(text) ? int.tryParse(text) : null;

  /// Parses integers or finite decimals; decimals are rounded.
  static int? _parseRounded(String text) {
    final whole = _parseWhole(text);
    if (whole != null) return whole;
    final decimal = double.tryParse(text);
    return decimal != null && decimal.isFinite ? decimal.round() : null;
  }

  // NUMBERS

  /// Converts to int. Decimal numbers are rounded; invalid values become 0.
  static int toInt(dynamic value) {
    if (value is bool) return value ? 1 : 0;
    if (value is int) return value;
    if (value is num) {
      if (!value.isFinite) return 0;
      return value.round();
    }
    return _parseRounded(value?.toString().trim() ?? '') ?? 0;
  }

  /// Converts to double. Invalid or non-finite values become 0.
  static double toDouble(dynamic value) {
    if (value is bool) return value ? 1.0 : 0.0;
    if (value is num) {
      final result = value.toDouble();
      return result.isFinite ? result : 0.0;
    }
    final result = double.tryParse(value?.toString().trim() ?? '');
    return result != null && result.isFinite ? result : 0.0;
  }

  /// Converts to int, returning null for missing, empty, or invalid values.
  /// Numeric decimals are rounded to preserve the original convenience behavior.
  static int? toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      return _parseRounded(text);
    }
    if (value is num && !value.isFinite) return null;
    if (value is! num && value is! bool) return null;
    return toInt(value);
  }

  /// Converts to int only when the value is a whole number.
  /// Rejects booleans, decimals, non-finite values, and invalid strings.
  static int? toIntStrictOrNull(dynamic value) {
    if (value == null || value is bool) return null;
    if (value is int) return value;

    if (value is num) {
      if (!value.isFinite || value != value.truncateToDouble()) {
        return null;
      }
      return value.toInt();
    }

    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    return _parseWhole(text);
  }

  /// Converts to double, returning null for missing or empty values.
  static double? toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isEmpty) return null;
    if (value is bool) return value ? 1.0 : 0.0;

    if (value is num) {
      final result = value.toDouble();
      return result.isFinite ? result : null;
    }

    if (value is! String) return null;
    final result = double.tryParse(value.trim());
    return result != null && result.isFinite ? result : null;
  }

  /// Strict nullable double conversion. Rejects booleans.
  static double? toDoubleStrictOrNull(dynamic value) {
    if (value == null || value is bool) return null;

    if (value is num) {
      final result = value.toDouble();
      return result.isFinite ? result : null;
    }

    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty) return null;

    final result = double.tryParse(text);
    return result != null && result.isFinite ? result : null;
  }

  /// Converts numeric input without forcing it to int or double.
  static num? toNumOrNull(dynamic value) {
    if (value == null || value is bool) return null;
    if (value is num) return value.isFinite ? value : null;
    if (value is! String) return null;

    final text = value.trim();
    if (text.isEmpty) return null;
    final result = num.tryParse(text);
    return result != null && result.isFinite ? result : null;
  }

  // STRINGS

  /// Never null. Missing values become an empty string.
  static String toStringValue(dynamic value) => value?.toString() ?? '';

  /// Returns null only when the value itself is null.
  static String? toStringOrNull(dynamic value) => value?.toString();

  /// Converts to string and trims surrounding whitespace.
  static String toTrimmedString(dynamic value) =>
      value?.toString().trim() ?? '';

  /// Returns null for missing or blank strings.
  static String? toNonEmptyStringOrNull(dynamic value) {
    final text = toTrimmedString(value);
    return text.isEmpty ? null : text;
  }

  // BOOLEANS

  /// Converts common boolean representations. Unknown values become false.
  static bool toBool(dynamic value) => toBoolOrNull(value) ?? false;

  /// Parses true/false, 1/0, yes/no, and y/n, case-insensitively.
  static bool? toBoolOrNull(dynamic value) {
    if (value is bool) return value;

    if (value is num) {
      if (!value.isFinite) return null;
      if (value == 1) return true;
      if (value == 0) return false;
      return null;
    }

    if (value is! String) return null;
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'n':
        return false;
      default:
        return null;
    }
  }

  // MAPS AND COLLECTIONS

  /// Converts a map into Map<String, dynamic>.
  /// Returns null for non-maps or maps with incompatible keys.
  static Map<String, dynamic>? toMapOrNull(dynamic value) {
    if (value is! Map) return null;
    try {
      return Map<String, dynamic>.from(value);
    } on TypeError {
      return null;
    }
  }

  /// Converts a list of maps. Invalid entries are skipped.
  /// Returns an empty list when the input is not a list.
  static List<Map<String, dynamic>> toMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    final result = <Map<String, dynamic>>[];

    for (final item in value) {
      final map = toMapOrNull(item);
      if (map != null) result.add(map);
    }
    return result;
  }

  /// Returns null when input is not a list; an empty list is valid.
  static List<Map<String, dynamic>>? toMapListOrNull(dynamic value) {
    if (value is! List) return null;
    return toMapList(value);
  }

  /// Converts list items to strings, skipping null entries.
  static List<String> toStringList(dynamic value) {
    if (value is! List) return <String>[];
    return value
        .where((item) => item != null)
        .map((item) => item.toString())
        .toList();
  }

  /// Converts list items to integers, skipping invalid entries.
  static List<int> toIntList(dynamic value) {
    if (value is! List) return <int>[];
    return value.map(toIntStrictOrNull).whereType<int>().toList();
  }

  /// Converts list items to doubles, skipping invalid entries.
  static List<double> toDoubleList(dynamic value) {
    if (value is! List) return <double>[];
    return value.map(toDoubleStrictOrNull).whereType<double>().toList();
  }

  /// Converts a map's values to integers, skipping invalid entries.
  static Map<String, int> toIntMap(dynamic value) {
    final map = toMapOrNull(value);
    if (map == null) return <String, int>{};

    final result = <String, int>{};
    for (final entry in map.entries) {
      final parsed = toIntStrictOrNull(entry.value);
      if (parsed != null) result[entry.key] = parsed;
    }
    return result;
  }

  // DATES AND TIMESTAMPS

  /// Parses ISO 8601 date strings and DateTime instances.
  /// Strings without a timezone designator are returned as local time.
  static DateTime? toDateTimeOrNull(dynamic value) {
    if (value is DateTime) return value;
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  /// Returns fallback or UTC epoch if parsing fails.
  /// Prefer toDateTimeOrNull for real order/payment timestamps.
  static DateTime toDateTime(dynamic value, {DateTime? fallback}) {
    return toDateTimeOrNull(value) ??
        fallback ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  /// Converts a Unix timestamp expressed in seconds to UTC.
  static DateTime? unixSecondsToDateTimeOrNull(dynamic value) {
    final seconds = toIntStrictOrNull(value);
    if (seconds == null) return null;
    try {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    } on ArgumentError {
      return null;
    }
  }

  /// Converts a Unix timestamp expressed in milliseconds to UTC.
  static DateTime? unixMillisecondsToDateTimeOrNull(dynamic value) {
    final milliseconds = toIntStrictOrNull(value);
    if (milliseconds == null) return null;
    try {
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    } on ArgumentError {
      return null;
    }
  }

  // ENUMS

  /// Matches enum names case-insensitively.
  /// For different backend values, use an explicit mapping in your model.
  static T? toEnumOrNull<T extends Enum>(dynamic value, List<T> values) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    for (final item in values) {
      if (item.name.toLowerCase() == text.toLowerCase()) return item;
    }
    return null;
  }

  // URLS

  /// Parses a URI. Does not require it to be a web URL.
  static Uri? toUriOrNull(dynamic value) {
    if (value is Uri) return value;
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    return Uri.tryParse(text);
  }

  /// Parses an absolute HTTP or HTTPS URL.
  static Uri? toHttpUriOrNull(dynamic value) {
    final uri = toUriOrNull(value);
    if (uri == null || !uri.hasScheme) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    if (uri.host.isEmpty) return null;
    return uri;
  }

  // DURATIONS

  /// Converts a Duration or a numeric/string millisecond value.
  static Duration? toDurationOrNull(dynamic value) {
    if (value is Duration) return value;
    final milliseconds = toIntStrictOrNull(value);
    if (milliseconds == null) return null;
    return Duration(milliseconds: milliseconds);
  }

  /// Converts a duration to milliseconds, returning null if invalid.
  static int? toMillisecondsOrNull(dynamic value) {
    if (value is Duration) return value.inMilliseconds;
    return toIntStrictOrNull(value);
  }

  // JSON

  /// Decodes a JSON string or passes through an already-decoded value.
  /// Returns null when decoding fails (indistinguishable from the JSON
  /// literal `null`).
  static dynamic decodeJsonOrNull(dynamic value) {
    if (value is! String) return value;
    final text = value.trim();
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  /// Encodes a value as JSON. Returns null if encoding fails.
  static String? toJsonStringOrNull(dynamic value) {
    try {
      return jsonEncode(value);
    } on JsonUnsupportedObjectError {
      return null;
    }
  }

  /// Decodes JSON and returns it only if the result is an object.
  static Map<String, dynamic>? jsonToMapOrNull(dynamic value) =>
      toMapOrNull(decodeJsonOrNull(value));

  /// Decodes JSON and returns it only if the result is an array.
  static List<dynamic>? jsonToListOrNull(dynamic value) {
    final decoded = decodeJsonOrNull(value);
    return decoded is List ? decoded : null;
  }

  // SAFE LIST INDEXES

  /// Returns a valid index, or null when out of bounds.
  static int? toSafeIndex(dynamic value, int length) {
    if (length <= 0) return null;
    final index = toIntStrictOrNull(value);
    if (index == null || index < 0 || index >= length) return null;
    return index;
  }

  /// Reads a list item safely, returning null for invalid indexes.
  static T? listItemOrNull<T>(List<T> items, dynamic index) {
    final safeIndex = toSafeIndex(index, items.length);
    if (safeIndex == null) return null;
    return items[safeIndex];
  }
}
