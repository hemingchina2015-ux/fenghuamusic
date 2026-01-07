import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import 'music_service.dart';

class PlayerController {
  // 单例模式
  static final PlayerController _instance = PlayerController._internal();
  factory PlayerController() => _instance;
  PlayerController._internal();

  final AudioPlayer player = AudioPlayer();

  // 核心通知器
  final ValueNotifier<SongModel?> currentSongNotifier =
      ValueNotifier<SongModel?>(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  // 当前播放列表
  List<SongModel> playlist = [];

  void init() {
    // 监听播放完成自动下一首
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  /// 核心：播放歌曲逻辑
  Future<void> playSong(SongModel song, List<SongModel> currentList) async {
    playlist = currentList;

    // 1. 立即更新 UI 显示播放条，并进入加载状态
    currentSongNotifier.value = song;
    isLoadingNotifier.value = true;

    // 2. 异步下载歌词（不阻塞音频播放）
    // 如果这首歌还没歌词，就开始下载
    if (song.lyrics == null) {
      _downloadLyricsAsync(song);
    }

    try {
      // 3. 获取音频地址
      String? url = await MusicService.getAudioUrl(song.source, song.songId);

      if (url != null && url.isNotEmpty) {
        await player.setUrl(url);
        player.play();
      } else {
        throw Exception("无法获取播放地址");
      }
    } catch (e) {
      debugPrint("❌ 播放失败: $e");
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// 异步下载歌词逻辑
  Future<void> _downloadLyricsAsync(SongModel song) async {
    try {
      // 传入标题和歌手，而不是 ID
      String? lrc = await MusicService.getLyrics(song.title, song.artist);

      if (lrc != null && lrc.isNotEmpty) {
        song.lyrics = lrc;

        // 刷新 UI
        if (currentSongNotifier.value?.songId == song.songId) {
          final current = currentSongNotifier.value;
          currentSongNotifier.value = null;
          currentSongNotifier.value = current;
        }
      }
    } catch (e) {
      debugPrint("⚠️ 歌词处理失败: $e");
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

// 全局单例
final playerController = PlayerController();
