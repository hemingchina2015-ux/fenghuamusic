import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'models/song_model.dart';
import 'services/music_service.dart';
import 'widgets/player_buttons.dart';

class PlayerDetailPage extends StatefulWidget {
  final AudioPlayer player;
  final SongModel song;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const PlayerDetailPage({
    super.key,
    required this.player,
    required this.song,
    this.onNext,
    this.onPrevious,
  });

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late SongModel _displaySong; // 当前页面显示的歌曲信息
  bool _showLyrics = false;
  var _lyricModel; // 歌词模型

  @override
  void initState() {
    super.initState();
    _displaySong = widget.song;
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    if (widget.player.playing) _rotationController.repeat();

    // 监听播放状态来控制封面旋转
    widget.player.playingStream.listen((playing) {
      if (mounted) {
        playing ? _rotationController.repeat() : _rotationController.stop();
      }
    });

    _loadLyrics();
  }

  // 加载/刷新歌词
  void _loadLyrics() async {
    // 这里简单演示，实际应根据 _displaySong 去获取
    // final lyrics = await MusicService.getLyrics(_displaySong);
    // setState(() { _lyricModel = ... });
  }

  // 处理手动切歌：不仅触发回调，还要更新当前页面的显示
  void _handleNext() {
    if (widget.onNext != null) {
      widget.onNext!();
      // 注意：这里需要延时或者通过监听流来更新 _displaySong
      // 简单处理：我们假设 HomePage 的 currentSong 会变，
      // 实际上更好的做法是详情页也监听 player 的 metadata
    }
  }

  void _handlePrevious() {
    if (widget.onPrevious != null) {
      widget.onPrevious!();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          // 1. 背景高斯模糊
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(_displaySong.cover),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

          // 2. 主体内容
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 歌名歌手
                Text(
                  _displaySong.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  _displaySong.artist,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // 3. 中间部分：封面或歌词切换
                GestureDetector(
                  onTap: () => setState(() => _showLyrics = !_showLyrics),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.width * 0.8,
                    child: _showLyrics
                        ? const Center(child: Text("歌词功能加载中..."))
                        : Center(
                            child: RotationTransition(
                              turns: _rotationController,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white10,
                                    width: 10,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    _displaySong.cover,
                                    width: 260,
                                    height: 260,
                                    fit: BoxFit.cover,
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
                    final duration = widget.player.duration ?? Duration.zero;
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
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(color: Colors.white60),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // 5. 控制按钮栏 (全部复用封装好的组件)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      PlayModeButton(player: widget.player, size: 30),
                      ControlButton(
                        icon: Icons.skip_previous_rounded,
                        size: 45,
                        onTap: widget.onPrevious, // 回调主页逻辑
                      ),
                      // 大号播放按钮
                      PlayPauseButton(player: widget.player, size: 70),
                      ControlButton(
                        icon: Icons.skip_next_rounded,
                        size: 45,
                        onTap: widget.onNext, // 回调主页逻辑
                      ),
                      FavoriteButton(song: _displaySong, size: 30),
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
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
