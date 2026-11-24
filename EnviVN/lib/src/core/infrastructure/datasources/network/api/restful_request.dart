import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../configs/env_config.dart';
import 'configs/base_response.dart';
import 'configs/endpoint.dart';
import 'network_logger.dart';

class RestfulRequest {
  final http.Client _client;
  final bool _ownsClient;
  final String defaultBaseUrl;
  final Duration timeout;

  RestfulRequest({
    http.Client? client,
    String? defaultBaseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       defaultBaseUrl = defaultBaseUrl ?? EnvConfig.backendBaseUrl;

  void close() {
    if (_ownsClient) _client.close();
  }

  Future<BaseResponse> requestData(
    EndpointType endpoint, {
    bool showErrorToast = true,
  }) async {
    final activeBaseUrl = endpoint.customBaseUrl ?? defaultBaseUrl;
    Uri uri;
    String? body;
    final apiKey = EnvConfig.clientApiKey;
    final headers = <String, String>{
      ...DefaultHeader.instance.defaultHeader,
      if (apiKey.isNotEmpty) 'x-api-key': apiKey,
      if (endpoint.header != null) ...endpoint.header!,
    };
    try {
      uri = Uri.parse('$activeBaseUrl${endpoint.path}');
      if (endpoint.method == HttpMethod.get && endpoint.params is Map<String, dynamic>) {
        final mergedParams = <String, String>{
          ...uri.queryParameters,
          ...(endpoint.params as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString())),
        };
        uri = uri.replace(queryParameters: mergedParams);
      }
      body = (endpoint.method != HttpMethod.get && endpoint.params != null) ? jsonEncode(endpoint.params) : null;
    } catch (e) {
      if (kDebugMode) {
        NetworkLogger.logError(url: '$activeBaseUrl${endpoint.path}', error: 'Invalid request: $e');
      }
      return const BaseResponse(isSuccess: false, message: 'Yêu cầu dữ liệu không hợp lệ.');
    }
    if (kDebugMode) {
      NetworkLogger.logSend(url: uri.toString(), method: endpoint.method.value, headers: headers, params: endpoint.params);
    }
    try {
      http.Response response;
      switch (endpoint.method) {
        case HttpMethod.get:
          response = await _client.get(uri, headers: headers).timeout(timeout);
          break;
        case HttpMethod.post:
          response = await _client.post(uri, headers: headers, body: body).timeout(timeout);
          break;
        case HttpMethod.put:
          response = await _client.put(uri, headers: headers, body: body).timeout(timeout);
          break;
        case HttpMethod.delete:
          response = await _client.delete(uri, headers: headers, body: body).timeout(timeout);
          break;
      }
      dynamic json;
      try {
        json = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        json = response.body;
      }
      if (kDebugMode) {
        NetworkLogger.logReceive(url: uri.toString(), statusCode: response.statusCode, body: json);
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return BaseResponse.fromSuccessJson(json);
      }
      return BaseResponse.fromErrorJson(json);
    } on SocketException catch (e) {
      if (kDebugMode) {
        NetworkLogger.logError(url: uri.toString(), error: 'Network error: $e');
      }
      return const BaseResponse(isSuccess: false, message: 'Không thể kết nối đến máy chủ EnviVN. Vui lòng kiểm tra Internet!');
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        NetworkLogger.logError(url: uri.toString(), error: 'Timeout: $e');
      }
      return const BaseResponse(isSuccess: false, message: 'Kết nối mạng quá hạn (Timeout). Vui lòng thử lại!');
    } catch (e) {
      if (kDebugMode) {
        NetworkLogger.logError(url: uri.toString(), error: '$e');
      }
      return const BaseResponse(isSuccess: false, message: 'Đã xảy ra sự cố khi tải dữ liệu. Vui lòng thử lại!');
    }
  }
}
