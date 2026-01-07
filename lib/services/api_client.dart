import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // 💡 如果落雪 App 能播，请确认它使用的是哪个 API 地址。Render 经常被墙或休眠。
  static const String baseUrl = 'https://lxmusicapi.onrender.com';
  static const String apiKey = 'share-v2';

  // 增加重试与延迟退避，默认 3 次重试，超时 30 秒
  // 默认改为更短的重试与超时，避免长时间阻塞（针对音频接口我们会在上层并行尝试）
  static Future<dynamic> get(
    String path, {
    int retries = 0,
    int timeoutSeconds = 30,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        debugPrint("🚀 发起请求 (attempt $attempt/$retries): $url");
        final response = await http
            .get(
              url,
              headers: {
                'X-Request-Key': apiKey,
                // 模拟更真实移动端 UA，有时能绕过托管服务限制
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
                'Accept': '*/*',
                'Connection': 'keep-alive',
              },
            )
            .timeout(Duration(seconds: timeoutSeconds));

        debugPrint("🔁 响应状态: ${response.statusCode} (attempt $attempt)");

        if (response.statusCode == 200) {
          final body = response.body;
          // 尝试解析为 JSON，解析失败时返回原始文本（很多歌词接口返回纯文本）
          try {
            return json.decode(body);
          } catch (e) {
            debugPrint("⚠️ 非 JSON 响应，返回原始文本: $e");
            return body;
          }
        } else {
          // 打印响应体以便调试（404/400/500 等）
          debugPrint("⚠️ 服务器返回错误: ${response.statusCode}");
          try {
            debugPrint("⚠️ 响应体（非 200）: ${response.body}");
          } catch (_) {}
          // 对于 5xx 错误尝试重试，对于 4xx 一般不重试
          if (response.statusCode >= 500 && attempt < retries) {
            final backoff = Duration(seconds: 2 * attempt);
            debugPrint("ℹ️ 服务器错误，${backoff.inSeconds}s 后重试...");
            await Future.delayed(backoff);
            continue;
          } else {
            return null;
          }
        }
      } catch (e) {
        debugPrint("❌ API 连接异常 (attempt $attempt): $e");
        if (attempt < retries) {
          final backoff = Duration(seconds: 2 * attempt);
          debugPrint("ℹ️ ${backoff.inSeconds}s 后重试...");
          await Future.delayed(backoff);
          continue;
        }
      }
    }
    debugPrint("🚫 所有重试失败: $url");
    return null;
  }
}
