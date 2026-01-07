import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://lxmusicapi.onrender.com';
  // 备选盐值参考: 'lx-music/wer.tempmusic.tk/v1' 或 'six-v2'
  static const String salt = 'lx-music/wer.tempmusic.tk/v1';

  static Future<dynamic> get(
    String path, {
    int retries = 1,
    bool isExternal = false,
  }) async {
    final url = isExternal ? Uri.parse(path) : Uri.parse('$baseUrl$path');

    // --- 核心修正：尝试 path + salt 并转为大写 ---
    final signStr = path + salt;
    final sign = md5
        .convert(utf8.encode(signStr))
        .toString()
        .toUpperCase(); // 很多 API 验证要求大写

    debugPrint("======== [API 签名对比调试] ========");
    debugPrint("🔗 URL: $url");
    if (!isExternal) {
      debugPrint("✍️ 拼接字符串: $signStr");
      debugPrint("✍️ 最终生成签名 (Upper): $sign");
    }
    debugPrint("==================================");

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
                      'X-Requested-With':
                          'XMLHttpRequest', // 增加该 Header 模拟真实客户端
                    },
            )
            .timeout(
              Duration(seconds: isExternal ? 15 : 50),
            ); // 进一步延长至 50s 确保 Render 唤醒

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 403) {
          debugPrint("🚫 签名验证仍失败 [403]。如果 MD5 已对，尝试更换 Salt。");
        }
      } catch (e) {
        debugPrint("⏳ 尝试 ${attempt + 1} 出错: $e");
        if (attempt == retries) rethrow;
      }
    }
    return null;
  }
}
