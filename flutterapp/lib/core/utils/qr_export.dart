import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:qr_flutter/qr_flutter.dart';

/// Renders [data] as a PNG with a white background and quiet zone, so a bank
/// app can read it from the gallery.
Future<Uint8List> renderQrPng(
  String data, {
  double size = 900,
  double margin = 80,
}) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: ui.Color(0xFF000000),
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: ui.Color(0xFF000000),
    ),
  );
  final total = size + margin * 2;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, total, total),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  canvas.translate(margin, margin);
  painter.paint(canvas, ui.Size(size, size));
  final image = await recorder.endRecording().toImage(
    total.toInt(),
    total.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
