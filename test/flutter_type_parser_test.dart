import 'package:flutter_type_parser/flutter_type_parser.dart';
import 'package:test/test.dart';

enum OrderType { eatHere, takeaway }

void main() {
  group('numbers', () {
    test('toInt keeps convenience conversion behavior', () {
      expect(FlutterTypeParser.toInt(12), 12);
      expect(FlutterTypeParser.toInt(12.7), 13);
      expect(FlutterTypeParser.toInt(true), 1);
      expect(FlutterTypeParser.toInt('bad'), 0);
      expect(FlutterTypeParser.toInt(null), 0);
    });

    test('strict integer rejects decimals and booleans', () {
      expect(FlutterTypeParser.toIntStrictOrNull('12'), 12);
      expect(FlutterTypeParser.toIntStrictOrNull(12.0), 12);
      expect(FlutterTypeParser.toIntStrictOrNull(12.7), isNull);
      expect(FlutterTypeParser.toIntStrictOrNull(true), isNull);
      expect(FlutterTypeParser.toIntStrictOrNull('bad'), isNull);
    });

    test('nullable numeric conversions handle invalid values', () {
      expect(FlutterTypeParser.toIntOrNull(''), isNull);
      expect(FlutterTypeParser.toIntOrNull('12'), 12);
      expect(FlutterTypeParser.toDoubleOrNull('2.5'), 2.5);
      expect(FlutterTypeParser.toDoubleStrictOrNull(true), isNull);
      expect(FlutterTypeParser.toNumOrNull('3.5'), 3.5);
      expect(FlutterTypeParser.toNumOrNull('NaN'), isNull);
    });
  });

  group('strings and booleans', () {
    test('string helpers', () {
      expect(FlutterTypeParser.toStringValue(null), '');
      expect(FlutterTypeParser.toStringOrNull(null), isNull);
      expect(FlutterTypeParser.toTrimmedString('  hi  '), 'hi');
      expect(FlutterTypeParser.toNonEmptyStringOrNull('  '), isNull);
    });

    test('boolean variants', () {
      expect(FlutterTypeParser.toBool('YES'), isTrue);
      expect(FlutterTypeParser.toBool('0'), isFalse);
      expect(FlutterTypeParser.toBoolOrNull('maybe'), isNull);
      expect(FlutterTypeParser.toBoolOrNull(2), isNull);
      expect(FlutterTypeParser.toBool('maybe'), isFalse);
    });
  });

  group('collections', () {
    test('maps and map lists safely parse', () {
      expect(FlutterTypeParser.toMapOrNull({'id': 1}), {'id': 1});
      expect(FlutterTypeParser.toMapOrNull(null), isNull);
      expect(
        FlutterTypeParser.toMapList([
          {'id': 1},
          'bad',
          {'id': 2},
        ]),
        [
          {'id': 1},
          {'id': 2},
        ],
      );
      expect(FlutterTypeParser.toMapListOrNull(null), isNull);
      expect(FlutterTypeParser.toMapListOrNull(<dynamic>[]), isEmpty);
    });

    test('typed lists skip invalid values', () {
      expect(FlutterTypeParser.toStringList([1, null, 'x']), ['1', 'x']);
      expect(FlutterTypeParser.toIntList([1, '2', 3.5, 'bad']), [1, 2]);
      expect(FlutterTypeParser.toDoubleList([1, '2.5', 'bad']), [1.0, 2.5]);
      expect(FlutterTypeParser.toIntMap({'a': 1, 'b': '2', 'c': 2.5}), {
        'a': 1,
        'b': 2,
      });
    });
  });

  group('dates and enums', () {
    test('parses ISO dates and Unix timestamps', () {
      expect(
        FlutterTypeParser.toDateTimeOrNull('2026-10-19T10:30:00Z')!.isUtc,
        isTrue,
      );
      expect(FlutterTypeParser.toDateTimeOrNull('invalid'), isNull);
      expect(
        FlutterTypeParser.unixSecondsToDateTimeOrNull(0),
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      expect(
        FlutterTypeParser.unixMillisecondsToDateTimeOrNull('0'),
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    });

    test('enum names match case-insensitively', () {
      expect(
        FlutterTypeParser.toEnumOrNull('takeaway', OrderType.values),
        OrderType.takeaway,
      );
      expect(
        FlutterTypeParser.toEnumOrNull('unknown', OrderType.values),
        isNull,
      );
    });
  });

  group('URLs, durations and JSON', () {
    test('only accepts HTTP(S) in web URL helper', () {
      expect(
        FlutterTypeParser.toHttpUriOrNull('https://example.com')!.host,
        'example.com',
      );
      expect(FlutterTypeParser.toHttpUriOrNull('file:///tmp/a'), isNull);
      expect(FlutterTypeParser.toUriOrNull('/relative/path'), isNotNull);
    });

    test('duration helpers use milliseconds', () {
      expect(
        FlutterTypeParser.toDurationOrNull('1500'),
        const Duration(milliseconds: 1500),
      );
      expect(
        FlutterTypeParser.toMillisecondsOrNull(const Duration(seconds: 2)),
        2000,
      );
      expect(FlutterTypeParser.toDurationOrNull('bad'), isNull);
    });

    test('JSON helpers handle objects, lists and malformed input', () {
      expect(FlutterTypeParser.jsonToMapOrNull('{"id":1}'), {'id': 1});
      expect(FlutterTypeParser.jsonToListOrNull('[1,2]'), [1, 2]);
      expect(FlutterTypeParser.decodeJsonOrNull('{bad'), isNull);
      expect(FlutterTypeParser.toJsonStringOrNull({'id': 1}), '{"id":1}');
    });
  });

  group('regressions', () {
    test('HTTP URLs with fragments are accepted', () {
      expect(
        FlutterTypeParser.toHttpUriOrNull('https://example.com/a#top'),
        isNotNull,
      );
    });

    test('hex strings are not parsed as integers', () {
      expect(FlutterTypeParser.toIntStrictOrNull('0x1A'), isNull);
      expect(FlutterTypeParser.toInt('0x1A'), 0);
    });

    test('lenient int rounds decimal strings like decimal numbers', () {
      expect(FlutterTypeParser.toInt('12.7'), 13);
      expect(FlutterTypeParser.toIntOrNull('12.7'), 13);
      expect(FlutterTypeParser.toIntOrNull('NaN'), isNull);
    });

    test('empty results are mutable', () {
      FlutterTypeParser.toMapList(null).add({});
      FlutterTypeParser.toStringList(null).add('x');
      FlutterTypeParser.toIntList(null).add(1);
      FlutterTypeParser.toDoubleList(null).add(1);
      FlutterTypeParser.toIntMap(null)['a'] = 1;
    });

    test('non-encodable JSON returns null', () {
      expect(FlutterTypeParser.toJsonStringOrNull(Object()), isNull);
    });
  });

  group('safe indexes', () {
    test('rejects invalid indexes', () {
      expect(FlutterTypeParser.toSafeIndex('1', 3), 1);
      expect(FlutterTypeParser.toSafeIndex(3, 3), isNull);
      expect(FlutterTypeParser.toSafeIndex(-1, 3), isNull);
      expect(FlutterTypeParser.toSafeIndex(1.5, 3), isNull);
      expect(FlutterTypeParser.listItemOrNull(['a', 'b'], 1), 'b');
      expect(FlutterTypeParser.listItemOrNull(['a'], 4), isNull);
    });
  });
}
