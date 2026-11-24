import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Infrastructure HTTP logger isolated from pure domain BaseResult.
class NetworkLogger {
  NetworkLogger._();

  static void logSend({
    required String url,
    required String method,
    Map<String, String>? headers,
    dynamic params,
  }) {
    if (!kDebugMode) return;
    try {
      final buffer = StringBuffer();
      buffer.writeln('[API SEND] $method $url');
      if (params != null) {
        buffer.writeln(_prettyJson(params));
      }
      debugPrint(buffer.toString());
    } catch (_) {}
  }

  static void logReceive({
    required String url,
    required int statusCode,
    dynamic body,
  }) {
    if (!kDebugMode) return;
    try {
      final buffer = StringBuffer();
      buffer.writeln('[API RECV $statusCode] $url');
      if (body != null) {
        buffer.writeln(_prettyJson(body));
      }
      debugPrint(buffer.toString());
    } catch (_) {}
  }

  static void logError({required String url, required String error}) {
    if (!kDebugMode) return;
    try {
      debugPrint('[API ERROR] $url -> $error');
    } catch (_) {}
  }

  static String _prettyJson(
    dynamic raw, {
    int maxLines = 12,
    int maxChars = 350,
  }) {
    if (raw == null) return 'null';
    String formatted;
    try {
      if (raw is Map || raw is List) {
        formatted = const JsonEncoder.withIndent('  ').convert(raw);
      } else if (raw is String) {
        try {
          formatted = const JsonEncoder.withIndent(
            '  ',
          ).convert(jsonDecode(raw));
        } catch (_) {
          formatted = raw;
        }
      } else {
        formatted = raw.toString();
      }
    } catch (_) {
      formatted = raw.toString();
    }
    final lines = formatted.split('\n');
    if (lines.length > maxLines) {
      return '${lines.take(maxLines).join('\n')}\n... [${lines.length - maxLines} hidden lines]';
    }
    if (formatted.length > maxChars) {
      return '${formatted.substring(0, maxChars)}\n... [truncated]';
    }
    return formatted;
  }
}
