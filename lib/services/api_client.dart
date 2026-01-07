import 'dart:convert';
import 'package:crypto/crypto.dart'; // 请确保已经在 pubspec.yaml 添加了 crypto
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://lxmusicapi.onrender.com';
  // 这是从你提供的 JS 代码中解析出的最新盐值
  static const String salt = 'lx-music/wer.tempmusic.tk/v1';

  static Future<dynamic> get(String path, {int retries = 1}) async {
    final url = Uri.parse('$baseUrl$path');

    // 生成动态签名：md5(路径 + 盐值)
    final signStr = path + salt;
    final sign = md5.convert(utf8.encode(signStr)).toString();

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        debugPrint("🚀 请求 API: $path (尝试 ${attempt + 1})");
        final response = await http
            .get(
              url,
              headers: {
                'X-Request-Key': sign,
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
              },
            )
            .timeout(const Duration(seconds: 30)); // 延长到 30 秒，给 Render 唤醒时间

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          debugPrint("⚠️ 接口返回错误: ${response.statusCode} 内容: ${response.body}");
        }
      } catch (e) {
        debugPrint("❌ 请求异常 ($path): $e");
        if (attempt == retries) rethrow; // 最后一次尝试失败则抛出
      }
    }
    return null;
  }
}
