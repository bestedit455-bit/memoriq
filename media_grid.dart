import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'theme.dart';
import 'glass.dart';
import 'media_service.dart';
import 'viewer_page.dart'; 
import 'store_service.dart'; 
import 'vault_service.dart'; 

class MediaGrid extends StatefulWidget {
  final RequestType type;
  const MediaGrid({super.key, required this.type});

  @override
  State<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<MediaGrid>
    with AutomaticKeepAliveClientMixin {
  List<AssetEntity> _items = [];
  final Set<String> _selected = {};
  final ScrollController _sc = ScrollController();
  bool _loading = true;
  final ValueNotifier<String> _monthLabel = ValueNotifier('');

  @override
  bool get wantKeepAlive => true;

  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
    _sc.addListener(_onScroll);
  }

  Future<void> _load() async {
    final ok = await MediaService.requestPermission();
    if (!ok) {
      setState(() => _loading = false);
      return;
    }
    final list = await MediaService.loadAssets(widget.type);
    MediaService.preload(list, 0, 120);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }
  void _updateMonth(int index) {
  if (index < 0 || index >= _items.length) return;
  final d = _items[index].createDateTime;
  const m = ['Jan','Feb','Mar','Apr','May','Jun',
             'Jul','Aug','Sep','Oct','Nov','Dec'];
  _monthLabel.value = '${m[d.month - 1]} ${d.year}';
  }

  void _onScroll() {
    final rowHeight = MediaQuery.of(context).size.width / 3;
    final firstRow = (_sc.offset / rowHeight).floor();
    final from = firstRow * 3;
    _updateMonth(from);
    MediaService.preload(_items, from + 30, 90);
    if (from > 90) {
      MediaService.preload(_items, from - 60, 60);
    }
  }

  void _toggle(AssetEntity a) {
    setState(() {
      if (!_selected.remove(a.id)) _selected.add(a.id);
    });
  }

  Future<void> _share() async {
    final chosen = _items.where((e) => _selected.contains(e.id)).toList();
    final files = <XFile>[];
    for (final a in chosen) {
      final f = await a.originFile;
      if (f != null) files.add(XFile(f.path));
    }
    if (files.isNotEmpty) {
      await Share.shareXFiles(files);
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    return Stack(
      children: [
        GridView.builder(
          controller: _sc,
          cacheExtent: 2500,
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: _items.length,
          itemBuilder: (context, i) {
            final a = _items[i];
            final sel = _selected.contains(a.id);
            return GestureDetector(
              onLongPress: () => _toggle(a),
              onTap: () async {
  if (_selecting) {
    _toggle(a);
  } else {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ViewerPage(items: _items, start: i),
      ),
    );
    if (deleted == true) _load();
  }
},
              child: _Tile(asset: a, selected: sel),
);
},
),
        if (_selecting)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: LiquidGlass(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(_selected.clear),
                  ),
                  Text(
                    '${_selected.length} selected',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share, color: AppColors.gold),
                    onPressed: _share,
                  ),
                  IconButton(
  icon: const Icon(Icons.visibility_off, color: Colors.white),
  onPressed: () async {
    final chosen =
        _items.where((e) => _selected.contains(e.id)).toList();
    final has = await VaultService.hasPassword();
    if (!has) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open vault once to set password')),
      );
      return;
    }
    await VaultService.hide(chosen);
    setState(_selected.clear);
    _load();
  },
),
IconButton(
  icon: const Icon(Icons.delete_outline, color: Colors.white),
  onPressed: () async {
    final chosen =
        _items.where((e) => _selected.contains(e.id)).toList();
    await StoreService.moveToTrash(chosen);
    setState(_selected.clear);
    _load();
  },
),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final AssetEntity asset;
  final bool selected;
  const _Tile({required this.asset, required this.selected});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: MediaService.thumb(asset),
      builder: (context, snap) {
        final data = snap.data;
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColors.surface),
              if (data != null)
                Image.memory(
                  data,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              if (asset.type == AssetType.video)
                const Positioned(
                  right: 6,
                  bottom: 6,
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 20),
                ),
              if (selected)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.35),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.check_circle,
                         color: AppColors.gold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
