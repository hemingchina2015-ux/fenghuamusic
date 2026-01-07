import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://lxmusicapi.onrender.com';
  // 盐值保持不变
  static const String salt = 'lx-music/wer.tempmusic.tk/v1';

  static Future<dynamic> get(
    String path, {
    int retries = 1,
    bool isExternal = false,
  }) async {
    final url = isExternal ? Uri.parse(path) : Uri.parse('$baseUrl$path');

    String sign = "";
    if (!isExternal) {
      // --- 模拟野花 JS 的核心逻辑 ---
      // 1. 提取路径中的数字和字母部分 (等同于 JS 的 /(?:\d\w)+/g)
      final regExp = RegExp(r'(?:\d\w)+');
      final matches = regExp.allMatches(path).map((m) => m.group(0)).toList();

      // 2. 将匹配列表转为 JSON 字符串 (JS 的 JSON.stringify(matches))
      // 注意：JS 的 JSON.stringify 对数组的处理非常严格，不能有空格
      final jsonMatches = json.encode(matches);

      // 3. 拼接盐值
      final signStr = jsonMatches + salt;

      // 4. 计算 MD5
      sign = md5.convert(utf8.encode(signStr)).toString();

      debugPrint("======== [野花算法模拟调试] ========");
      debugPrint("🧩 提取到的 Matches: $matches");
      debugPrint("📝 最终 SignStr: $signStr");
      debugPrint("✍️ 生成的 Sign: $sign");
      debugPrint("=================================");
    }

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
                          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                      'X-Requested-With': 'XMLHttpRequest',
                    },
            )
            .timeout(const Duration(seconds: 40)); // 缩短单次超时，增加重试效率

        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
        debugPrint("🚫 响应失败 [${response.statusCode}]: ${response.body}");
      } catch (e) {
        debugPrint("⏳ 尝试 ${attempt + 1} 异常: $e");
        if (attempt == retries) rethrow;
      }
    }
    return null;
  }
}
