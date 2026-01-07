import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://lxmusicapi.onrender.com';
  // 保持之前的盐值，这是落雪脚本的关键
  static const String salt = 'lx-music/wer.tempmusic.tk/v1';

  static Future<dynamic> get(String path, {int retries = 1}) async {
    final url = Uri.parse('$baseUrl$path');

    // 生成签名逻辑保持不变：md5(路径 + 盐值)
    final signStr = path + salt;
    final sign = md5.convert(utf8.encode(signStr)).toString();

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        debugPrint("🚀 正在伪装 PC 客户端请求: $path");
        final response = await http
            .get(
              url,
              headers: {
                'X-Request-Key': sign,
                // 💡 模拟落雪音乐 PC 版真实 User-Agent
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) lx-music-desktop/2.0.0 Chrome/102.0.5005.167 Electron/19.0.8 Safari/537.36',
                'Accept': '*/*',
                'Host': 'lxmusicapi.onrender.com',
                'Connection': 'keep-alive',
              },
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          debugPrint("⚠️ API 响应异常 [${response.statusCode}]: ${response.body}");
        }
      } catch (e) {
        debugPrint("❌ 网络请求错误: $e");
        if (attempt == retries) rethrow;
      }
    }
    return null;
  }
}
