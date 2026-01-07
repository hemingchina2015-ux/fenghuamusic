import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'api_client.dart';

// 播放模式枚举
enum PlayMode { order, shuffle, loopAll, oneLoop }

// 全局状态通知器
final ValueNotifier<PlayMode> playModeNotifier = ValueNotifier(PlayMode.order);
final ValueNotifier<List<String>> favoriteIdsNotifier = ValueNotifier([]);

class MusicService {
  static const String _favKey = 'favorite_songs_list';

  /// 初始化服务
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_favKey) ?? [];
    favoriteIdsNotifier.value = list
        .map((item) {
          try {
            return (json.decode(item)['songId'] as String);
          } catch (e) {
            return "";
          }
        })
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// 1. 搜索歌曲
  static Future<List<SongModel>> searchKuwo(String keyword) async {
    // 这里的搜索接口路径需根据你的 API 实际情况调整，通常为 /search/...
    final response = await ApiClient.get(
      '/search/searchMusicBykeyWord?nm=$keyword&pn=1&rn=30',
    );
    if (response != null && response['data'] != null) {
      List list = response['data']['list'];
      return list.map((item) => SongModel.fromKuwo(item)).toList();
    }
    return [];
  }

  /// 2. 获取播放地址 (带动态签名)
  // static Future<String?> getAudioUrl(String source, String songId) async {
  //   // 路径格式：/url/来源/ID/音质
  //   final String path = '/url/$source/$songId/128k';
  //   final response = await ApiClient.get(path);

  //   if (response != null) {
  //     // 兼容两种返回格式：1. 直接返回data为url，2. 返回data对象里包含url
  //     if (response['code'] == 0 || response['code'] == 200) {
  //       return response['data'].toString();
  //     }
  //   }
  //   return null;
  // }

  /// 3. 获取歌词 (核心：实现边播边下的底层支持)
  // static Future<String?> getLyrics(String title, String artist) async {
  //   // 对参数进行编码，防止空格和特殊字符导致 URL 崩溃
  //   final query = Uri.encodeComponent('$title $artist');
  //   final url = 'https://lrclib.net/api/search?q=$query';

  //   try {
  //     debugPrint("🔍 正在从 LRCLIB 搜索歌词: $title - $artist");

  //     // 注意：这里用 http 直接请求，不经过 ApiClient (因为 LRCLIB 不需要落雪的签名)
  //     final response = await http
  //         .get(Uri.parse(url))
  //         .timeout(const Duration(seconds: 10));

  //     if (response.statusCode == 200) {
  //       List data = json.decode(response.body);
  //       if (data.isNotEmpty) {
  //         // 优先获取带时间轴的歌词 (syncedLyrics)
  //         String? syncedLrc = data[0]['syncedLyrics'];
  //         if (syncedLrc != null && syncedLrc.isNotEmpty) {
  //           debugPrint("✅ 成功获取 LRCLIB 同步歌词");
  //           return syncedLrc;
  //         }
  //         // 如果没有同步歌词，退而求其次用普通歌词
  //         return data[0]['plainLyrics'];
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint("❌ LRCLIB 歌词请求异常: $e");
  //   }
  //   return null;
  // }

  /// 4. 收藏/取消收藏逻辑
  static Future<void> toggleFavorite(SongModel song) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> fullJsonList = prefs.getStringList(_favKey) ?? [];

    int index = fullJsonList.indexWhere(
      (item) => SongModel.fromJson(json.decode(item)).songId == song.songId,
    );

    List<String> currentIds = List.from(favoriteIdsNotifier.value);

    if (index != -1) {
      fullJsonList.removeAt(index);
      currentIds.remove(song.songId);
    } else {
      fullJsonList.add(json.encode(song.toJson()));
      currentIds.add(song.songId);
    }

    await prefs.setStringList(_favKey, fullJsonList);
    favoriteIdsNotifier.value = currentIds;
  }

  /// 5. 获取收藏列表
  static Future<List<SongModel>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_favKey) ?? [];
    return list.map((item) => SongModel.fromJson(json.decode(item))).toList();
  }

  static Future<String?> getLyrics(String title, String artist) async {
    final query = Uri.encodeComponent('$title $artist');
    final fullUrl = 'https://lrclib.net/api/search?q=$query';

    try {
      // 使用 ApiClient 请求，isExternal 为 true 不会加签名头
      final response = await ApiClient.get(fullUrl, isExternal: true);

      if (response != null && response is List && response.isNotEmpty) {
        // 优先同步歌词
        String? synced = response[0]['syncedLyrics'];
        if (synced != null && synced.isNotEmpty) return synced;
        return response[0]['plainLyrics'];
      }
    } catch (e) {
      debugPrint("❌ 歌词获取失败，请手动在浏览器访问测试: $fullUrl");
    }
    return null;
  }

  /// 保持 getAudioUrl 的核心逻辑
  static Future<String?> getAudioUrl(String source, String songId) async {
    final String path = '/url/$source/$songId/128k';
    final response = await ApiClient.get(path);

    // 如果 code 为 1，说明签名 salt 需要更换
    if (response != null && response['code'] == 0) {
      return response['data'].toString();
    }
    return null;
  }
}
