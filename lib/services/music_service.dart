import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'api_client.dart'; // 确保你已有这个文件

// 播放模式枚举
enum PlayMode { order, shuffle, loopAll, oneLoop }

// 全局通知器
final ValueNotifier<PlayMode> playModeNotifier = ValueNotifier(PlayMode.order);
final ValueNotifier<List<String>> favoriteIdsNotifier = ValueNotifier([]);

class MusicService {
  static const String _favKey = 'favorite_songs_list';

  // 初始化：从本地存储加载收藏的 ID 列表
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_favKey) ?? [];
    favoriteIdsNotifier.value = list.map((item) {
      return (json.decode(item)['songId'] as String);
    }).toList();
  }

  // 搜索酷我音乐
  static Future<List<SongModel>> searchKuwo(String keyword) async {
    // 这里的 path 根据你的 ApiClient 实际接口调整
    final response = await ApiClient.get(
      '/search/searchMusicBykeyWord?nm=$keyword&pn=1&rn=30',
    );
    if (response != null && response['data'] != null) {
      List list = response['data']['list'];
      return list.map((item) => SongModel.fromKuwo(item)).toList();
    }
    return [];
  }

  // 获取播放地址 (解决你点击后加载的问题)
  static Future<String?> getAudioUrl(String source, String songId) async {
    // 假设接口路径为 /url/kw/songId/quality
    final response = await ApiClient.get('/url/$source/$songId/128k');
    if (response != null && response['url'] != null) {
      return response['url'].toString();
    }
    return null;
  }

  // 切换收藏状态
  static Future<bool> toggleFavorite(SongModel song) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> fullJsonList = prefs.getStringList(_favKey) ?? [];

    int index = fullJsonList.indexWhere(
      (item) => SongModel.fromJson(json.decode(item)).songId == song.songId,
    );

    List<String> currentIds = List.from(favoriteIdsNotifier.value);

    if (index != -1) {
      fullJsonList.removeAt(index);
      currentIds.remove(song.songId);
      await prefs.setStringList(_favKey, fullJsonList);
      favoriteIdsNotifier.value = currentIds;
      return false;
    } else {
      fullJsonList.add(json.encode(song.toJson()));
      currentIds.add(song.songId);
      await prefs.setStringList(_favKey, fullJsonList);
      favoriteIdsNotifier.value = currentIds;
      return true;
    }
  }

  // 获取所有收藏歌曲
  static Future<List<SongModel>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_favKey) ?? [];
    return list.map((item) => SongModel.fromJson(json.decode(item))).toList();
  }
}
