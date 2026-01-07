class SongModel {
  final String title;
  final String artist;
  final String source;
  final String songId;
  final String cover;
  String? lyrics; // 新增：缓存下载好的歌词

  SongModel({
    required this.title,
    required this.artist,
    required this.source,
    required this.songId,
    required this.cover,
    this.lyrics,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'source': source,
    'songId': songId,
    'cover': cover,
  };

  // 专门处理酷我搜索结果的工厂构造函数
  factory SongModel.fromKuwo(Map<String, dynamic> item) {
    // 1. 清洗歌名和歌手名中的转义字符
    String cleanTitle = (item['SONGNAME'] ?? '未知')
        .toString()
        .replaceAll("&nbsp;", " ")
        .replaceAll("&amp;", "&");

    String cleanArtist = (item['ARTIST'] ?? '未知')
        .toString()
        .replaceAll("&nbsp;", " ")
        .replaceAll("&amp;", "&");

    // 2. 处理歌曲 ID (移除 MUSIC_ 前缀)
    String rid = (item['MUSICRID'] ?? '').toString().replaceAll('MUSIC_', '');

    // 3. 处理封面图逻辑 (如果 albumId 为 0 或为空，使用默认图)
    String albumId = item['ALBUMID']?.toString() ?? "";
    String coverUrl = "https://img1.kuwo.cn/star/albumcover/500/default.jpg";
    if (albumId.isNotEmpty && albumId != "0") {
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

  // factory SongModel.fromJson(Map<String, dynamic> json, String src) {
  //   return SongModel(
  //     title: (json['name'] ?? json['title'] ?? '未知歌曲').toString(),
  //     artist: (json['artist'] ?? json['singer'] ?? '未知歌手').toString(),
  //     source: src,
  //     songId: (json['songmid'] ?? json['hash'] ?? json['id']).toString(),
  //     cover:
  //         json['img'] ??
  //         "https://p2.music.126.net/6y-UleORpfX7nz69VovZog==/109951163431936628.jpg",
  //   );
  // }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      title: json['title'] ?? '未知',
      artist: json['artist'] ?? '未知',
      source: json['source'] ?? 'kw',
      songId: json['songId']?.toString() ?? '',
      cover: json['cover'] ?? '',
      lyrics: json['lyrics'],
    );
  }

  // factory SongModel.fromJson(Map<String, dynamic> json) => SongModel(
  //   title: json['title'],
  //   artist: json['artist'],
  //   source: json['source'],
  //   songId: json['songId'],
  //   cover: json['cover'],
  // );
}
