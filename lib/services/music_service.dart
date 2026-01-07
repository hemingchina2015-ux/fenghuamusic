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

  // 初始化方法
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_favKey) ?? [];
    favoriteIdsNotifier.value = list.map((item) {
      return (json.decode(item)['songId'] as String);
    }).toList();
  }

  // 1. 搜索方法 (对应 HomePage 调用)
  static Future<List<SongModel>> searchKuwo(String keyword) async {
    final response = await ApiClient.get(
      '/search/searchMusicBykeyWord?nm=$keyword&pn=1&rn=30',
    );
    if (response != null && response['data'] != null) {
      List list = response['data']['list'];
      return list.map((item) => SongModel.fromKuwo(item)).toList();
    }
    return [];
  }

  // 2. 获取播放地址方法 (对应 HomePage 调用)
  static Future<String?> getAudioUrl(String source, String songId) async {
    final response = await ApiClient.get('/url/$source/$songId/128k');
    if (response != null && response['url'] != null) {
      return response['url'].toString();
    }
    return null;
  }

  // 切换收藏
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

  static Future<List<SongModel>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_favKey) ?? [];
    return list.map((item) => SongModel.fromJson(json.decode(item))).toList();
  }
}
