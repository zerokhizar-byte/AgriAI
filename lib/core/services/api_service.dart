import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  final http.Client _client;

  ApiService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<dynamic> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse(url).replace(
        queryParameters: queryParameters,
      );

      final response = await _client.get(
        uri,
        headers: headers,
      );

      return _handleResponse(response);
    } catch (error) {
      throw ApiException(
        'Unable to connect to the server: $error',
      );
    }
  }

  Future<dynamic> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: body == null ? null : jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (error) {
      throw ApiException(
        'Unable to connect to the server: $error',
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    throw ApiException(
      _getErrorMessage(data, statusCode),
      statusCode: statusCode,
    );
  }

  String _getErrorMessage(
    dynamic data,
    int statusCode,
  ) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message is String && message.isNotEmpty) {
        return message;
      }

      final error = data['error'];

      if (error is String && error.isNotEmpty) {
        return error;
      }
    }

    return 'Request failed with status code $statusCode.';
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }

    return '$message (Status code: $statusCode)';
  }
}