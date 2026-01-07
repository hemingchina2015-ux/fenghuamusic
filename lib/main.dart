import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print("🚀 正在初始化后台音频服务...");
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.fenghua.music.channel.audio',
      androidNotificationChannelName: '风华音乐播放控制',
      androidNotificationOngoing: true,
    );
    print("✅ 后台音频服务已就绪");
  } catch (e) {
    // 如果这里报错，千万不要忽略，因为它直接导致后续无法播放
    print("❌ 严重错误：后台服务未能启动。请检查 MainActivity 是否继承了 AudioServiceActivity");
    return; // 停止运行，排查原生配置
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '风华音乐',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        primaryColor: Colors.blueAccent,
      ),
      home: const HomePage(),
    );
  }
}
