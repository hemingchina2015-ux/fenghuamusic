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

    // 1. 立即更新 UI，显示播放条
    currentSongNotifier.value = song;
    isLoadingNotifier.value = true;

    try {
      // 2. 获取真正的播放地址
      String? url = await MusicService.getAudioUrl(song.source, song.songId);

      if (url != null && url.isNotEmpty) {
        await player.setUrl(url);
        player.play();
      } else {
        throw Exception("无法获取播放地址");
      }
    } catch (e) {
      debugPrint("播放失败: $e");
      // 这里可以抛出异常让 UI 层显示 SnackBar
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
