import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'models/song_model.dart';
import 'services/player_controller.dart';
import 'widgets/player_buttons.dart';

class PlayerDetailPage extends StatefulWidget {
  final AudioPlayer player;
  final SongModel song; // 初始传入的歌曲

  const PlayerDetailPage({super.key, required this.player, required this.song});

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    if (widget.player.playing) {
      _rotationController.repeat();
    }

    // 监听播放状态控制旋转
    widget.player.playingStream.listen((playing) {
      if (!mounted) return;
      if (playing) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  // 时间格式化工具方法
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // 关键：使用 ValueListenableBuilder 监听全局当前歌曲
    // 这样在详情页切歌时，封面和文字会自动刷新
    return ValueListenableBuilder<SongModel?>(
      valueListenable: playerController.currentSongNotifier,
      builder: (context, currentSong, _) {
        // 如果控制器里没歌（异常情况），则使用进入页面时传入的歌
        final displaySong = currentSong ?? widget.song;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 35,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              // 1. 背景高斯模糊
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(displaySong.cover),
                    fit: BoxFit.cover,
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),

              // 2. 主体内容
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // 歌曲信息
                    Text(
                      displaySong.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displaySong.artist,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    // 3. 封面旋转部分
                    GestureDetector(
                      onTap: () => setState(() => _showLyrics = !_showLyrics),
                      child: Center(
                        child: RotationTransition(
                          turns: _rotationController,
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white10,
                                width: 12,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                displaySong.cover,
                                fit: BoxFit.cover,
                                errorBuilder: (context, _, __) => Container(
                                  color: Colors.grey[900],
                                  child: const Icon(
                                    Icons.music_note,
                                    size: 80,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // 4. 进度条
                    StreamBuilder<Duration>(
                      stream: widget.player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration =
                            widget.player.duration ?? Duration.zero;
                        return Column(
                          children: [
                            Slider(
                              activeColor: Colors.blueAccent,
                              inactiveColor: Colors.white24,
                              value: position.inMilliseconds.toDouble(),
                              max: duration.inMilliseconds.toDouble().clamp(
                                0,
                                double.infinity,
                              ),
                              onChanged: (value) => widget.player.seek(
                                Duration(milliseconds: value.toInt()),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween, // 修正拼写错误
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // 5. 控制按钮栏
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          PlayModeButton(player: widget.player, size: 28),
                          ControlButton(
                            icon: Icons.skip_previous_rounded,
                            size: 45,
                            onTap: () => playerController.playPrevious(),
                          ),
                          // 使用监听了加载状态的播放按钮
                          ValueListenableBuilder<bool>(
                            valueListenable: playerController.isLoadingNotifier,
                            builder: (context, loading, _) {
                              return PlayPauseButton(
                                player: widget.player,
                                isLoading: loading,
                                size: 75,
                              );
                            },
                          ),
                          ControlButton(
                            icon: Icons.skip_next_rounded,
                            size: 45,
                            onTap: () => playerController.playNext(),
                          ),
                          FavoriteButton(song: displaySong, size: 28),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
