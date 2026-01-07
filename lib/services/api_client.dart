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
    final signStr = path + salt;
    final sign = md5.convert(utf8.encode(signStr)).toString();

    debugPrint("DEBUG: Path=$path | Sign=$sign");
    // --- 新增详细调试日志 ---
    debugPrint("======== [API 签名调试] ========");
    debugPrint("1. 请求完整 URL: $url");
    debugPrint("2. 参与计算的路径: $path");
    debugPrint("3. 参与计算的盐值: $salt");
    debugPrint("4. 最终拼接字符串: $signStr");
    debugPrint("5. 生成的 MD5 签名: $sign");
    debugPrint("===============================");

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        debugPrint("🚀 正在伪装 PC 客户端请求: $path");
        final response = await http
            .get(
              url,
              headers: {
                'X-Request-Key': sign,
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) lx-music-desktop/2.0.0 Safari/537.36',
                'Accept': 'application/json, text/plain, */*',
                'X-Requested-With': 'XMLHttpRequest',
                'Referer': 'https://lxmusicapi.onrender.com/',
              },
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 403) {
          debugPrint("🚫 403 错误：签名或权限失效。返回内容: ${response.body}");
        }
      } catch (e) {
        debugPrint("❌ 网络请求错误: $e");
        if (attempt == retries) rethrow;
      }
    }
    return null;
  }
}
