import 'dart:io';

import 'package:image/image.dart';

void main() {
  final source = File('assets/images/app_icon.webp');
  if (!source.existsSync()) {
    stderr.writeln('Source icon not found: ${source.path}');
    exit(1);
  }

  final bytes = source.readAsBytesSync();
  final image = decodeWebP(bytes);
  if (image == null) {
    stderr.writeln('Failed to decode ${source.path}.');
    exit(1);
  }

  final target = File('assets/images/app_icon.png');
  target.writeAsBytesSync(encodePng(image));
  stdout.writeln('Generated ${target.path}');
}
