import 'dart:convert';

import 'package:flutter/foundation.dart';

Future<Map<String, Object?>> decodeJsonObject(String body) {
  return compute(_decodeJsonObject, body);
}

Future<Map<String, Object?>?> decodeJsonObjectOrNull(String body) {
  return compute(_decodeJsonObjectOrNull, body);
}

Future<List<Map<String, Object?>>> decodeJsonList(String body) {
  return compute(_decodeJsonList, body);
}

Map<String, Object?> _decodeJsonObject(String body) {
  return jsonDecode(body) as Map<String, Object?>;
}

Map<String, Object?>? _decodeJsonObjectOrNull(String body) {
  return jsonDecode(body) as Map<String, Object?>?;
}

List<Map<String, Object?>> _decodeJsonList(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! List) {
    throw const FormatException('Expected a JSON list.');
  }
  return decoded.whereType<Map<String, Object?>>().toList(growable: false);
}
