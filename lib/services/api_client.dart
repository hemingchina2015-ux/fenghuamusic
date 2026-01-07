import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://lxmusicapi.onrender.com';
  static const String apiKey = 'share-v2'; // 💡 确定为静态 Key

  static Future<dynamic> get(
    String path, {
    int retries = 2,
    bool isExternal = false,
  }) async {
    final url = isExternal ? Uri.parse(path) : Uri.parse('$baseUrl$path');

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(
              url,
              headers: isExternal
                  ? {}
                  : {
                      'X-Request-Key': apiKey,
                      // 'User-Agent': 'lx-music-request/1.2.0',
                      'User-Agent':
                          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                      'Accept': 'application/json',
                    },
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          // 这里如果是 LRCLIB 返回的是数组，json.decode 会返回 List
          return json.decode(response.body);
        }
      } catch (e) {
        debugPrint("⏳ 请求重试中... $e");
        if (attempt == retries) rethrow;
      }
    }
    return null;
  }
}
