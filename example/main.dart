// ignore_for_file: avoid_print
import 'package:flutter_type_parser/flutter_type_parser.dart';

void main() {
  final json = <String, dynamic>{
    'id': '42',
    'is_enabled': 'yes',
    'created_at': '2026-10-19T10:30:00Z',
    'image_url': 'https://example.com/a.png#v2',
    'extras': [
      {'name': 'cheese'},
      'bad entry',
    ],
  };

  print(FlutterTypeParser.toIntStrictOrNull(json['id'])); // 42
  print(FlutterTypeParser.toBoolOrNull(json['is_enabled'])); // true
  print(FlutterTypeParser.toDateTimeOrNull(json['created_at']));
  print(FlutterTypeParser.toHttpUriOrNull(json['image_url']));
  print(FlutterTypeParser.toMapList(json['extras'])); // [{name: cheese}]
}
