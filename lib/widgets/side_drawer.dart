import 'package:flutter/material.dart';

class SideDrawer extends StatelessWidget {
  final VoidCallback onShowFavorites; // 新增回调
  const SideDrawer({super.key, required this.onShowFavorites});
  // const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121212), // 深黑色背景
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 3),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.white12,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            accountName: const Text(
              "风华音乐用户",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text("huawei_2020@music.com"),
          ),
          _buildMenuItem(Icons.favorite, "我的收藏", Colors.redAccent, () {
            Navigator.pop(context); // 关闭侧边栏
            onShowFavorites(); // 触发主页刷新
          }),
          _buildMenuItem(
            Icons.download_done_rounded,
            "本地音乐",
            Colors.greenAccent,
            () {},
          ),
          _buildMenuItem(
            Icons.history_rounded,
            "播放历史",
            Colors.orangeAccent,
            () {},
          ),
          const Spacer(),
          const Divider(color: Colors.white10, indent: 20, endIndent: 20),
          _buildMenuItem(Icons.settings_outlined, "设置中心", Colors.grey, () {}),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      onTap: onTap,
      horizontalTitleGap: 0,
    );
  }
}
