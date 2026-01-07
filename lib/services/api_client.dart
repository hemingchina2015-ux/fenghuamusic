import 'dart:convert';
import 'package:crypto/crypto.dart'; // 需要添加依赖
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // 基础地址
  static const String baseUrl = 'https://lxmusicapi.onrender.com';

  // 这里的 Key 逻辑在 JS 里是动态生成的，经过分析它的 Salt（盐值）是基于接口路径的
  // 这里的 apiKey 其实是 JS 里的校验盐值
  static const String salt = 'lx-music/wer.tempmusic.tk/v1';

  static Future<dynamic> get(String path, {int retries = 0}) async {
    final url = Uri.parse('$baseUrl$path');

    // --- 核心修复：生成动态 X-Request-Key ---
    // 逻辑：md5(path + salt)
    final signStr = path + salt;
    final sign = md5.convert(utf8.encode(signStr)).toString();

    for (int attempt = 1; attempt <= (retries + 1); attempt++) {
      try {
        debugPrint("🚀 请求路径: $path");
        final response = await http
            .get(
              url,
              headers: {
                'X-Request-Key': sign, // 使用动态生成的签名
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
                'Accept': '*/*',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          debugPrint("⚠️ 服务器返回错误: ${response.statusCode} - ${response.body}");
          return null;
        }
      } catch (e) {
        debugPrint("❌ 请求异常: $e");
        if (attempt > retries) return null;
      }
    }
  }
}
