// 在 music_service.dart 同级新建 http_helper.dart
import 'package:http/http.dart' as http;

class HttpHelper {
  static Future<http.Response> get(Uri url) async {
    print("--- 发起请求 ---");
    print("URL: $url");
    final res = await http.get(url, headers: {'X-Request-Key': 'share-v2'});
    print("状态: ${res.statusCode}");
    print("内容: ${res.body}"); // 这行能帮我们看清 400 的真相
    return res;
  }
}
