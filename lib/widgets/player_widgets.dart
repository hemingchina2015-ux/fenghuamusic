import 'package:fenghuamusic/models/song_model.dart';
import 'package:fenghuamusic/services/music_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

// 封装处理 404 的网络图片，支持 Referer 绕过部分限制
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxShape shape;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _buildPlaceholder();

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'http://www.kuwo.cn/',
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.black87, shape: shape),
      child: const Icon(Icons.music_note, color: Colors.white24, size: 30),
    );
  }
}

// 详情页控制按钮组：补全了上一首/下一首的功能调用
class ControlButtons extends StatelessWidget {
  final AudioPlayer player;
  const ControlButtons({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 上一首
        IconButton(
          icon: const Icon(
            Icons.skip_previous_rounded,
            size: 45,
            color: Colors.white,
          ),
          onPressed: () {
            if (player.hasPrevious) {
              player.seekToPrevious();
            } else {
              // 如果是单曲或列表头，可以自行定义逻辑，比如 seek(0)
              player.seek(Duration.zero);
            }
          },
        ),

        const SizedBox(width: 30),

        // 播放/暂停核心按钮
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final processingState = snapshot.data?.processingState;
            final playing = snapshot.data?.playing ?? false;

            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 85,
                height: 85,
                child: const CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
              );
            } else {
              return IconButton(
                icon: Icon(
                  playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                ),
                iconSize: 85,
                color: Colors.blueAccent,
                onPressed: () => playing ? player.pause() : player.play(),
              );
            }
          },
        ),

        const SizedBox(width: 30),

        // 下一首
        IconButton(
          icon: const Icon(
            Icons.skip_next_rounded,
            size: 45,
            color: Colors.white,
          ),
          onPressed: () {
            // 注意：如果在 HomePage 没用 ConcatenatingAudioSource，
            // 这里的 seekToNext 可能没反应，建议通过回调由外部 HomePage 控制
            player.seekToNext();
          },
        ),
      ],
    );
  }
}

// 在 widgets/player_widgets.dart 中添加
class FavoriteButton extends StatelessWidget {
  final SongModel song;
  final double size;

  const FavoriteButton({super.key, required this.song, this.size = 24});

  @override
  Widget build(BuildContext context) {
    // 监听全局收藏 ID 列表的变化
    return ValueListenableBuilder<List<String>>(
      valueListenable: favoriteIdsNotifier,
      builder: (context, favIds, child) {
        final isFav = favIds.contains(song.songId);

        return IconButton(
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: size,
          ),
          color: isFav ? Colors.redAccent : Colors.white70,
          onPressed: () async {
            await MusicService.toggleFavorite(song);
          },
        );
      },
    );
  }
}
