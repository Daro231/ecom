import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Screenshots taken with `binding.takeScreenshot(name)` are written to
/// `screenshots/NAME.png`
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final f = File('screenshots/$name.png');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes);
    return true;
  },
);
