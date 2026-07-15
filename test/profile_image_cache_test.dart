import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fixflow_app/utils/performance_utils.dart';

void main() {
  test('decodes raw base64 payloads', () {
    final rawBytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    final payload = base64Encode(rawBytes);

    expect(PerformanceUtils.decodeImage(payload), isNotNull);
  });

  test('normalizes data URI payloads before decoding', () {
    final rawBytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    final payload = 'data:image/png;base64,${base64Encode(rawBytes)}';

    expect(PerformanceUtils.decodeImage(payload), isNotNull);
  });
}
