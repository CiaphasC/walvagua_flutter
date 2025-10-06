import 'dart:convert';

class Base64Utils {
  Base64Utils._();

  static String tripleDecode(String encoded) {
    var value = encoded.trim();
    for (var i = 0; i < 3; i++) {
      final decodedBytes = base64Decode(value);
      value = utf8.decode(decodedBytes);
    }
    return value;
  }
}
