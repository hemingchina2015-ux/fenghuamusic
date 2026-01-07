import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song_model.dart';
import 'music_service.dart';

class PlayerController {
  static final PlayerController _instance = PlayerController._internal();
  factory PlayerController() => _instance;
  PlayerController._internal();

  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<SongModel?> currentSongNotifier =
      ValueNotifier<SongModel?>(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  List<SongModel> playlist = [];

  void init() {
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  Future<void> playSong(SongModel song, List<SongModel> currentList) async {
    playlist = currentList;
    currentSongNotifier.value = song;
    isLoadingNotifier.value = true;

    // 异步下载歌词（不阻塞播放）
    if (song.lyrics == null) {
      _downloadLyricsAsync(song);
    }

    try {
      // 获取音频地址
      String? url = await MusicService.getAudioUrl(song.source, song.songId);
      debugPrint("🎵 尝试播放真实 URL: $url");

      // 核心修正：防止 ExoPlayer 打开 null 路径
      if (url != null &&
          url.isNotEmpty &&
          url != "null" &&
          url.startsWith("http")) {
        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            // 💡 修复 background 模式下的 MediaItem 断言错误
            tag: MediaItem(
              id: song.songId,
              album: song.artist,
              title: song.title,
              // 如果封面无效（404），则不传入 artUri
              artUri:
                  (song.cover.isNotEmpty && !song.cover.contains("default.jpg"))
                  ? Uri.parse(song.cover)
                  : null,
            ),
          ),
        );
        player.play();
      } else {
        throw Exception("获取到的播放地址无效: $url");
      }
    } catch (e) {
      debugPrint("❌ 播放逻辑失败: $e");
      // 可以在这里通过弹窗告知用户服务器正在唤醒
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> _downloadLyricsAsync(SongModel song) async {
    try {
      // 调用 MusicService 的 LRCLIB 接口
      String? lrc = await MusicService.getLyrics(song.title, song.artist);
      if (lrc != null) {
        song.lyrics = lrc;
        // 触发 UI 刷新
        if (currentSongNotifier.value?.songId == song.songId) {
          final temp = currentSongNotifier.value;
          currentSongNotifier.value = null;
          currentSongNotifier.value = temp;
        }
      }
    } catch (e) {
      debugPrint("⚠️ 歌词下载失败: $e");
    }
  }

  void playNext() {
    if (playlist.isEmpty || currentSongNotifier.value == null) return;
    int index = playlist.indexWhere(
      (s) => s.songId == currentSongNotifier.value!.songId,
    );
    int nextIndex = (index + 1) % playlist.length;
    playSong(playlist[nextIndex], playlist);
  }

  void playPrevious() {
    if (playlist.isEmpty || currentSongNotifier.value == null) return;
    int index = playlist.indexWhere(
      (s) => s.songId == currentSongNotifier.value!.songId,
    );
    int prevIndex = (index - 1 + playlist.length) % playlist.length;
    playSong(playlist[prevIndex], playlist);
  }

  void dispose() => player.dispose();
}

final playerController = PlayerController();
