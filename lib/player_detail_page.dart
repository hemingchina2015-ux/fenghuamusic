import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'models/song_model.dart';
import 'services/player_controller.dart';
import 'widgets/player_buttons.dart';

class PlayerDetailPage extends StatefulWidget {
  final AudioPlayer player;
  final SongModel song;

  const PlayerDetailPage({super.key, required this.player, required this.song});

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _manualShowCover = false; // 用户是否手动切换回封面

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    if (widget.player.playing) _rotationController.repeat();

    // 监听播放状态控制旋转
    widget.player.playingStream.listen((playing) {
      if (!mounted) return;
      playing ? _rotationController.repeat() : _rotationController.stop();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SongModel?>(
      valueListenable: playerController.currentSongNotifier,
      builder: (context, currentSong, _) {
        final displaySong = currentSong ?? widget.song;
        // 自动逻辑：如果有歌词且用户没手动切封面，就显示歌词
        bool shouldShowLyrics = displaySong.lyrics != null && !_manualShowCover;

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
              // 1. 背景高斯模糊 (增加错误处理)
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(displaySong.cover),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      debugPrint("📸 背景图加载失败");
                    },
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      displaySong.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      displaySong.artist,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),

                    const Spacer(),

                    // 2. 中间区域：自动切换逻辑
                    GestureDetector(
                      onTap: () =>
                          setState(() => _manualShowCover = !_manualShowCover),
                      child: SizedBox(
                        height: 320,
                        child: shouldShowLyrics
                            ? _buildLyricView(displaySong.lyrics!)
                            : _buildRotatingCover(displaySong.cover),
                      ),
                    ),

                    const Spacer(),

                    // 3. 进度条
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
                                0.01,
                                double.infinity,
                              ),
                              onChanged: (v) => widget.player.seek(
                                Duration(milliseconds: v.toInt()),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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

                    // 4. 控制栏
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          PlayModeButton(player: widget.player),
                          ControlButton(
                            icon: Icons.skip_previous_rounded,
                            size: 45,
                            onTap: () => playerController.playPrevious(),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: playerController.isLoadingNotifier,
                            builder: (context, loading, _) => PlayPauseButton(
                              player: widget.player,
                              isLoading: loading,
                              size: 75,
                            ),
                          ),
                          ControlButton(
                            icon: Icons.skip_next_rounded,
                            size: 45,
                            onTap: () => playerController.playNext(),
                          ),
                          FavoriteButton(song: displaySong),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 💡 修改后的旋转封面方法，增加了加载中和错误处理逻辑
  Widget _buildRotatingCover(String url) {
    return Center(
      child: RotationTransition(
        turns: _rotationController,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10, width: 8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              url,
              fit: BoxFit.cover,
              // 加载中的占位：显示一个转圈的进度条
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white70,
                  ),
                );
              },
              // 错误处理：当图片 404 时显示 assets 里的默认图
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/default_cover.jpg',
                  fit: BoxFit.cover,
                  // 如果 assets 图片还没加，作为最后保底，显示一个带背景色的图标
                  errorBuilder: (context, err, stack) => Container(
                    color: Colors.blueGrey[800],
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLyricView(String lrc) {
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snapshot) {
        return LyricsReader(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          model: LyricsModelBuilder.create().bindLyricToMain(lrc).getModel(),
          position: snapshot.data?.inMilliseconds ?? 0,
          lyricUi: CustomLyricUI(), // 使用自定义 UI 类
          playing: widget.player.playing,
          emptyBuilder: () => const Center(
            child: Text("歌词下载中...", style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}

// 自定义歌词样式
class CustomLyricUI extends UINetease {
  @override
  Color getPlayingColor() => Colors.blueAccent;
  @override
  Color getOtherMainColor() => Colors.white54;
  @override
  TextStyle getPlayingMainTextStyle() => const TextStyle(
    color: Colors.blueAccent,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
}
