import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'theme.dart';
import 'glass.dart';
import 'media_grid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final PageController _pc = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'MEMORIQ',
          style: TextStyle(
            color: AppColors.gold,
            letterSpacing: 6,
            fontWeight: FontWeight.w300,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pc,
        onPageChanged: (i) => setState(() => _index = i),
        children: const [
          MediaGrid(type: RequestType.image),
          MediaGrid(type: RequestType.video),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 16),
        child: LiquidGlass(
          radius: 30,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.photo_outlined, 'Photos'),
              _navItem(1, Icons.videocam_outlined, 'Videos'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final active = _index == i;
    return GestureDetector(
      onTap: () {
        setState(() => _index = i);
        _pc.animateToPage(
          i,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? AppColors.gold : AppColors.textSecondary),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
