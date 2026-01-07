import 'package:flutter/material.dart';
import 'models/song_model.dart';
import 'services/music_service.dart';
import 'services/player_controller.dart'; // 引入新控制器
import 'widgets/mini_player.dart';
import 'widgets/side_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<SongModel> _songs = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 1. 初始化服务和播放器控制器
    await MusicService.init();
    playerController.init();
    // 2. 软件开启后自动加载收藏列表
    _loadFavorites();
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
      _showError("搜索失败，请检查网络或API状态");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "风华音乐",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 修正：删除了右上角多余的红心按钮，保持简洁
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
                : ValueListenableBuilder<SongModel?>(
                    valueListenable: playerController.currentSongNotifier,
                    builder: (context, currentSong, _) {
                      return ListView.builder(
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          bool isPlaying = currentSong?.songId == song.songId;
                          return ListTile(
                            leading: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    song.cover,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) => Container(
                                      color: Colors.white10,
                                      width: 50,
                                      height: 50,
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isPlaying)
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.equalizer,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isPlaying
                                    ? Colors.blueAccent
                                    : Colors.white,
                                fontWeight: isPlaying
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              song.artist,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () async {
                              try {
                                await playerController.playSong(song, _songs);
                              } catch (e) {
                                _showError("播放失败：歌曲可能暂不可用");
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      // 迷你播放条：监听控制器的当前歌曲变化
      bottomNavigationBar: ValueListenableBuilder<SongModel?>(
        valueListenable: playerController.currentSongNotifier,
        builder: (context, currentSong, _) {
          if (currentSong == null) return const SizedBox.shrink();
          return SafeArea(
            child: ValueListenableBuilder<bool>(
              valueListenable: playerController.isLoadingNotifier,
              builder: (context, isLoading, _) {
                return MiniPlayer(
                  player: playerController.player,
                  currentSong: currentSong,
                  isLoading: isLoading,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
