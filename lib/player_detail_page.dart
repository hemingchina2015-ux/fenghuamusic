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
  bool _manualShowCover = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    if (widget.player.playing) _rotationController.repeat();

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
              // 1. 背景层：使用 Image.network 替代 DecorationImage 以彻底拦截日志报错
              Positioned.fill(
                child: Image.network(
                  displaySong.cover,
                  fit: BoxFit.cover,
                  // 移除所有打印，失败时静默切换到本地默认图
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/default_cover.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // 高斯模糊层
              Positioned.fill(
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
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      displaySong.artist,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),

                    const Spacer(),

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

                    // 进度条
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

                    // 控制栏
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
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                );
              },
              // 失败时静默使用本地 assets 图片，不再尝试酷我无效地址
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/default_cover.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, stack) => Container(
                    color: Colors.blueGrey[900],
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white54,
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
          lyricUi: CustomLyricUI(),
          playing: widget.player.playing,
          emptyBuilder: () => const Center(
            child: Text("歌词下载中...", style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}

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
