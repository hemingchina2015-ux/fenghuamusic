import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  static Future<String?> getAudioUrl(String source, String songId) async {
    // 路径格式：/url/来源/ID/音质
    final String path = '/url/$source/$songId/128k';
    final response = await ApiClient.get(path);

    if (response != null) {
      // 兼容两种返回格式：1. 直接返回data为url，2. 返回data对象里包含url
      if (response['code'] == 0 || response['code'] == 200) {
        return response['data'].toString();
      }
    }
    return null;
  }

  /// 3. 获取歌词 (核心：实现边播边下的底层支持)
  static Future<String?> getLyrics(String source, String songId) async {
    // 根据落雪音乐 API 规范，歌词路径通常为 /lrc/来源/ID
    final String path = '/lrc/$source/$songId';
    try {
      final response = await ApiClient.get(path);
      if (response != null && response['data'] != null) {
        // 返回的通常是标准的 [00:00.00] 格式歌词文本
        return response['data'].toString();
      }
    } catch (e) {
      debugPrint("获取歌词异常: $e");
    }
    return null;
  }

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
}
