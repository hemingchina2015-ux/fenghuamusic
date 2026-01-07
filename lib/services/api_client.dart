import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://lxmusicapi.onrender.com';
  // ⚠️ 重点分析：如果日志持续 403，可能需要尝试新的盐值：'four-leaves' 或 'lx-music'
  static const String salt = 'lx-music/wer.tempmusic.tk/v1';

  static Future<dynamic> get(
    String path, {
    int retries = 1,
    bool isExternal = false,
  }) async {
    // 如果是 LRCLIB 等外部请求，直接拼接；否则拼接 baseUrl
    final url = isExternal ? Uri.parse(path) : Uri.parse('$baseUrl$path');

    // 计算签名
    final signStr = path + salt;
    final sign = md5.convert(utf8.encode(signStr)).toString();

    debugPrint("======== [请求详细调试] ========");
    debugPrint("🔗 目标 URL: $url");
    if (!isExternal) {
      debugPrint("🔑 参与计算路径: $path");
      debugPrint("🧂 当前使用盐值: $salt");
      debugPrint("✍️ 生成 MD5 签名: $sign");
    }
    debugPrint("===============================");

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(
              url,
              headers: isExternal
                  ? {}
                  : {
                      'X-Request-Key': sign,
                      'User-Agent':
                          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) lx-music-desktop/2.0.0 Safari/537.36',
                      'Accept': 'application/json, text/plain, */*',
                    },
            )
            .timeout(
              Duration(seconds: isExternal ? 15 : 45),
            ); // 给 Render 更多时间唤醒

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          debugPrint("🚫 请求失败 [${response.statusCode}]: ${response.body}");
        }
      } catch (e) {
        debugPrint("⏳ 尝试 ${attempt + 1} 异常: $e");
        if (attempt == retries) rethrow;
      }
    }
    return null;
  }
}
