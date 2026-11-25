import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'theme.dart';
import 'glass.dart';
import 'media_grid.dart';
import 'vault_page.dart';
import 'trash_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final PageController _pc = PageController();
  final ValueNotifier<bool> _selecting = ValueNotifier(false); 
  int _taps = 0;
DateTime _last = DateTime.now();

void _logoTap() {
  final now = DateTime.now();
  if (now.difference(_last).inMilliseconds > 800) _taps = 0;
  _last = now;
  _taps++;
  if (_taps >= 3) {
    _taps = 0;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VaultPage()),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: GestureDetector(
  onTap: _logoTap,
  child: const Text(
    'MEMORIQ',
    style: TextStyle(
      color: AppColors.gold,
      letterSpacing: 6,
      fontWeight: FontWeight.w300,
    ),
  ),
),
        centerTitle: true,
        actions: [
  IconButton(
    icon: const Icon(Icons.delete_outline,
        color: AppColors.textSecondary),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TrashPage()),
    ),
  ),
],
      ),
      body: ValueListenableBuilder<bool>(
  valueListenable: _selecting,
  builder: (context, selecting, _) {
    return PageView(
      controller: _pc,
      physics: selecting
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      onPageChanged: (i) => setState(() => _index = i),
      children: [
        MediaGrid(type: RequestType.image, selecting: _selecting),
        MediaGrid(type: RequestType.video, selecting: _selecting),
      ],
    );
  },
),
      bottomNavigationBar: ValueListenableBuilder<bool>(
  valueListenable: _selecting,
  builder: (context, selecting, _) {
    if (selecting) return const SizedBox.shrink();
    return Padding(
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
    );
  },
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
