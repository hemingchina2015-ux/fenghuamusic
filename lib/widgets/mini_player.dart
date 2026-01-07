import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../player_detail_page.dart';
import '../services/player_controller.dart';
import 'player_buttons.dart';

class MiniPlayer extends StatelessWidget {
  final AudioPlayer player;
  final SongModel currentSong;
  final bool isLoading;

  const MiniPlayer({
    super.key,
    required this.player,
    required this.currentSong,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击迷你播放条进入详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PlayerDetailPage(player: player, song: currentSong),
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
                  currentSong.cover,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    color: Colors.white10,
                    width: 52,
                    height: 52,
                    child: const Icon(Icons.music_note, color: Colors.white30),
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
                    currentSong.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentSong.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 3. 收藏按钮 (复用组件)
            FavoriteButton(song: currentSong),

            // 4. 控制按钮组 (修正顺序：上一首 -> 播放/暂停 -> 下一首)
            // 上一首
            ControlButton(
              icon: Icons.skip_previous_rounded,
              onTap: () => playerController.playPrevious(), // 直接调用控制器
              size: 28,
            ),

            // 播放/暂停/加载
            PlayPauseButton(player: player, isLoading: isLoading, size: 32),

            // 下一首
            ControlButton(
              icon: Icons.skip_next_rounded,
              onTap: () => playerController.playNext(), // 直接调用控制器
              size: 28,
            ),

            // 播放模式切换
            PlayModeButton(player: player),

            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}
