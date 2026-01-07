class SongModel {
  final String title;
  final String artist;
  final String source;
  final String songId;
  final String cover;
  // 核心改动：允许动态写入歌词
  String? lyrics;

  SongModel({
    required this.title,
    required this.artist,
    required this.source,
    required this.songId,
    required this.cover,
    this.lyrics,
  });

  // 1. 转换为 JSON，用于收藏夹持久化（记得带上 lyrics）
  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'source': source,
    'songId': songId,
    'cover': cover,
    'lyrics': lyrics, // 必须保存，否则下次打开收藏夹歌词就没了
  };

  // 2. 你的核心逻辑：专门处理酷我搜索结果，包含字符清洗和封面逻辑
  factory SongModel.fromKuwo(Map<String, dynamic> item) {
    // 保留你的逻辑：清洗歌名和歌手名中的转义字符
    String cleanTitle = (item['SONGNAME'] ?? '未知')
        .toString()
        .replaceAll("&nbsp;", " ")
        .replaceAll("&amp;", "&");

    String cleanArtist = (item['ARTIST'] ?? '未知')
        .toString()
        .replaceAll("&nbsp;", " ")
        .replaceAll("&amp;", "&");

    // 保留你的逻辑：处理歌曲 ID (移除 MUSIC_ 前缀)
    String rid = (item['MUSICRID'] ?? '').toString().replaceAll('MUSIC_', '');

    // 保留你的逻辑：处理封面图逻辑
    String albumId = item['ALBUMID']?.toString() ?? "";
    String coverUrl = "https://img1.kuwo.cn/star/albumcover/500/default.jpg";
    // 只有当 albumId 看起来合法时才拼接
    if (albumId.isNotEmpty && albumId != "0" && albumId != "null") {
      coverUrl = "http://img1.kuwo.cn/star/albumcover/500/$albumId.jpg";
    }

    return SongModel(
      title: cleanTitle,
      artist: cleanArtist,
      source: 'kw',
      songId: rid,
      cover: coverUrl,
    );
  }

  // 3. 从 JSON（收藏夹）恢复模型
  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      title: json['title'] ?? '未知',
      artist: json['artist'] ?? '未知',
      source: json['source'] ?? 'kw',
      songId: json['songId']?.toString() ?? '',
      cover: json['cover'] ?? '',
      lyrics: json['lyrics'], // 恢复缓存的歌词
    );
  }
}
