import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures a RepaintBoundary widget as PNG and invokes platform share sheet.
class StoryExportService {
  StoryExportService._();

  static Future<void> captureAndShare({
    required GlobalKey boundaryKey,
    required double pixelRatio,
    required String cityName,
    Rect? shareOrigin,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Missing repaint boundary');
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData;
    try {
      byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    } finally {
      image.dispose();
    }
    if (byteData == null) {
      throw StateError('Failed to encode story PNG');
    }
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/envivn_story_latest.png');
    await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path, mimeType: 'image/png')],
        text: 'Chất lượng không khí tại $cityName hôm nay • Ứng dụng EnviVN',
        subject: 'EnviVN - $cityName',
        sharePositionOrigin: shareOrigin,
      ),
    );
  }
}
