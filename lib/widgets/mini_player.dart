import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../player_detail_page.dart';
import 'player_buttons.dart'; // 引入封装的按钮组件

class MiniPlayer extends StatelessWidget {
  final AudioPlayer player;
  final SongModel? currentSong;
  final bool isLoading;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const MiniPlayer({
    super.key,
    required this.player,
    this.currentSong,
    required this.isLoading,
    this.onNext,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // 点击迷你播放条进入详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailPage(
              player: player,
              song: currentSong!,
              // 关键：将切歌逻辑也传给详情页，保证详情页切歌也有效
              onNext: onNext,
              onPrevious: onPrevious,
            ),
          ),
        );
      },
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. 歌曲封面
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  currentSong!.cover,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    color: Colors.grey,
                    width: 54,
                    height: 54,
                    child: const Icon(Icons.music_note),
                  ),
                ),
              ),
            ),

            // 2. 歌曲信息
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    currentSong!.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 3. 收藏按钮 (复用组件)
            FavoriteButton(song: currentSong!),

            // 4. 控制按钮组
            // 上一首
            ControlButton(
              icon: Icons.skip_previous_rounded,
              onTap: onPrevious,
              size: 28,
            ),

            // 播放/暂停/加载 (复用组件，自动处理加载状态)
            PlayPauseButton(player: player, isLoading: isLoading, size: 32),

            // 下一首
            ControlButton(
              icon: Icons.skip_next_rounded,
              onTap: onNext,
              size: 28,
            ),

            // 播放模式切换 (复用组件)
            PlayModeButton(player: player),

            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}
