import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../services/music_service.dart';

/// 1. 统一的收藏按钮
/// 监听全局 favoriteIdsNotifier，自动同步所有页面的收藏状态
class FavoriteButton extends StatelessWidget {
  final SongModel song;
  final double size;
  final Color? color;

  const FavoriteButton({
    super.key,
    required this.song,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: favoriteIdsNotifier,
      builder: (context, favIds, child) {
        final isFav = favIds.contains(song.songId);
        return IconButton(
          iconSize: size,
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? Colors.redAccent : (color ?? Colors.white70),
          ),
          onPressed: () => MusicService.toggleFavorite(song),
        );
      },
    );
  }
}

/// 2. 统一的播放模式切换按钮
/// 循环切换：顺序 -> 随机 -> 列表循环 -> 单曲循环
class PlayModeButton extends StatelessWidget {
  final AudioPlayer player;
  final double size;

  const PlayModeButton({super.key, required this.player, this.size = 24});

  Future<void> _cyclePlayMode() async {
    final current = playModeNotifier.value;
    PlayMode next;
    if (current == PlayMode.order) {
      next = PlayMode.shuffle;
    } else if (current == PlayMode.shuffle) {
      next = PlayMode.loopAll;
    } else if (current == PlayMode.loopAll) {
      next = PlayMode.oneLoop;
    } else {
      next = PlayMode.order;
    }
    playModeNotifier.value = next;

    // 同步给底层播放器实例
    switch (next) {
      case PlayMode.order:
        await player.setShuffleModeEnabled(false);
        await player.setLoopMode(LoopMode.off);
        break;
      case PlayMode.shuffle:
        await player.setShuffleModeEnabled(true);
        break;
      case PlayMode.loopAll:
        await player.setShuffleModeEnabled(false);
        await player.setLoopMode(LoopMode.all);
        break;
      case PlayMode.oneLoop:
        await player.setLoopMode(LoopMode.one);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayMode>(
      valueListenable: playModeNotifier,
      builder: (context, mode, child) {
        IconData icon;
        Color color = Colors.white70;
        switch (mode) {
          case PlayMode.order:
            icon = Icons.reorder_rounded;
            break;
          case PlayMode.shuffle:
            icon = Icons.shuffle_rounded;
            color = Colors.blueAccent;
            break;
          case PlayMode.loopAll:
            icon = Icons.repeat_rounded;
            color = Colors.blueAccent;
            break;
          case PlayMode.oneLoop:
            icon = Icons.repeat_one_rounded;
            color = Colors.blueAccent;
            break;
        }
        return IconButton(
          icon: Icon(icon, size: size, color: color),
          onPressed: _cyclePlayMode,
        );
      },
    );
  }
}

/// 3. 统一的上一首/下一首按钮
/// 这种按钮通常需要触发父级（HomePage）的列表索引切换，所以使用 VoidCallback
class ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const ControlButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size, color: Colors.white),
      onPressed: onTap,
    );
  }
}

/// 4. 统一的播放/暂停按钮
/// 自动根据播放器状态显示 播放 或 暂停 或 加载中
class PlayPauseButton extends StatelessWidget {
  final AudioPlayer player;
  final double size;
  final bool isLoading; // 外部传入的解析状态

  const PlayPauseButton({
    super.key,
    required this.player,
    this.size = 32,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // 如果外部正在解析 URL，显示加载圈
    if (isLoading) {
      return SizedBox(
        width: size + 16,
        height: size + 16,
        child: const Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    }

    // 否则根据播放器自身状态流显示
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 3),
          );
        } else if (playing != true) {
          return IconButton(
            icon: Icon(Icons.play_arrow_rounded, size: size),
            onPressed: player.play,
          );
        } else if (processingState != ProcessingState.completed) {
          return IconButton(
            icon: Icon(Icons.pause_rounded, size: size),
            onPressed: player.pause,
          );
        } else {
          return IconButton(
            icon: Icon(Icons.replay_rounded, size: size),
            onPressed: () => player.seek(Duration.zero),
          );
        }
      },
    );
  }
}
