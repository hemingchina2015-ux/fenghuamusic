import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import 'music_service.dart';

class PlayerController {
  // 单例模式，方便全局调用
  static final PlayerController _instance = PlayerController._internal();
  factory PlayerController() => _instance;
  PlayerController._internal();

  final AudioPlayer player = AudioPlayer();

  // 使用 ValueNotifier 让 UI 能监听到当前歌曲和加载状态的变化
  final ValueNotifier<SongModel?> currentSongNotifier =
      ValueNotifier<SongModel?>(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  // 当前的播放列表
  List<SongModel> playlist = [];

  void init() {
    // 监听播放完成自动下一首
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  // 核心：播放歌曲逻辑
  Future<void> playSong(SongModel song, List<SongModel> currentList) async {
    playlist = currentList;
    currentSongNotifier.value = song;
    isLoadingNotifier.value = true;

    try {
      debugPrint("正在请求歌曲: ${song.title} (ID: ${song.songId})");
      String? url = await MusicService.getAudioUrl(song.source, song.songId);

      if (url != null && url.isNotEmpty) {
        debugPrint("成功获取 URL: $url");
        await player.setUrl(url);
        player.play();
      } else {
        throw Exception("接口返回地址为空，请检查 API Key 是否有效");
      }
    } catch (e) {
      debugPrint("❌ 播放逻辑捕获异常: $e");
      // 这里的 rethrow 会传给 HomePage 的 _showError
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  // 下一首
  void playNext() {
    if (playlist.isEmpty || currentSongNotifier.value == null) return;
    int index = playlist.indexWhere(
      (s) => s.songId == currentSongNotifier.value!.songId,
    );
    int nextIndex = (index + 1) % playlist.length;
    playSong(playlist[nextIndex], playlist);
  }

  // 上一首
  void playPrevious() {
    if (playlist.isEmpty || currentSongNotifier.value == null) return;
    int index = playlist.indexWhere(
      (s) => s.songId == currentSongNotifier.value!.songId,
    );
    int prevIndex = (index - 1 + playlist.length) % playlist.length;
    playSong(playlist[prevIndex], playlist);
  }

  void dispose() {
    player.dispose();
  }
}

// 全局唯一的控制器实例
final playerController = PlayerController();
