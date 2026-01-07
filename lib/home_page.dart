import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'models/song_model.dart';
import 'services/music_service.dart';
import 'widgets/mini_player.dart';
import 'widgets/side_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AudioPlayer _player;
  final TextEditingController _searchController = TextEditingController();
  List<SongModel> _songs = [];
  SongModel? _currentSong;

  bool _isSearching = false;
  bool _isPlayerLoading = false;
  bool _isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  // 初始化应用：初始化服务 -> 设置播放器 -> 加载默认列表（收藏）
  Future<void> _initApp() async {
    await MusicService.init();
    _initAudioPlayer();
    _loadFavorites(); // 1. 软件开启后加载收藏列表
  }

  void _initAudioPlayer() {
    try {
      _player = AudioPlayer();

      // 监听播放完成，自动下一首
      _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          _playNext();
        }
      });

      setState(() {
        _isPlayerInitialized = true;
      });
    } catch (e) {
      debugPrint("播放器初始化失败: $e");
    }
  }

  // 加载收藏夹内容
  Future<void> _loadFavorites() async {
    setState(() => _isSearching = true);
    try {
      final favSongs = await MusicService.getFavorites();
      setState(() {
        _songs = favSongs;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  // 搜索歌曲
  Future<void> _searchSongs() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await MusicService.searchKuwo(_searchController.text);
      setState(() {
        _songs = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("搜索失败: $e")));
    }
  }

  // 核心修改：点击播放逻辑
  Future<void> _playSong(SongModel song) async {
    // 2. 立即显示播放条：先更新当前歌曲信息，让 UI 弹出来
    setState(() {
      _currentSong = song;
      _isPlayerLoading = true;
    });

    try {
      // 异步获取音频地址（下载/解析）
      String? url = await MusicService.getAudioUrl(song.source, song.songId);

      if (url != null && url.isNotEmpty) {
        await _player.setUrl(url);
        _player.play();
      } else {
        throw Exception("无法获取播放地址");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("播放失败: 歌曲可能无法下载或无版权")));
    } finally {
      if (mounted) {
        setState(() => _isPlayerLoading = false);
      }
    }
  }

  // 3. 统一的切歌逻辑
  void _playNext() {
    if (_songs.isEmpty || _currentSong == null) return;
    int index = _songs.indexWhere((s) => s.songId == _currentSong!.songId);
    int nextIndex = (index + 1) % _songs.length;
    _playSong(_songs[nextIndex]);
  }

  void _playPrevious() {
    if (_songs.isEmpty || _currentSong == null) return;
    int index = _songs.indexWhere((s) => s.songId == _currentSong!.songId);
    int prevIndex = (index - 1 + _songs.length) % _songs.length;
    _playSong(_songs[prevIndex]);
  }

  @override
  void dispose() {
    _player.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("风华音乐"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      drawer: SideDrawer(onShowFavorites: _loadFavorites),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "搜索歌曲、歌手...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _searchSongs,
                ),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _searchSongs(),
            ),
          ),

          // 歌曲列表
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      bool isPlaying = _currentSong?.songId == song.songId;
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            song.cover,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              color: Colors.grey,
                              width: 50,
                              height: 50,
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPlaying ? Colors.blueAccent : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () => _playSong(song),
                      );
                    },
                  ),
          ),
        ],
      ),
      // 迷你播放条
      bottomNavigationBar: SafeArea(
        child: (_isPlayerInitialized && _currentSong != null)
            ? MiniPlayer(
                player: _player,
                currentSong: _currentSong,
                isLoading: _isPlayerLoading,
                onNext: _playNext,
                onPrevious: _playPrevious,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
