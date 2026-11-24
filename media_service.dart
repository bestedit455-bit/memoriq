import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

class MediaService {
  static final Map<String, Uint8List> _cache = {};
  static const int _maxCache = 600;

  static Future<bool> requestPermission() async {
    final ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  static Future<List<AssetEntity>> loadAssets(RequestType type) async {
    final paths = await PhotoManager.getAssetPathList(
      type: type,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    if (paths.isEmpty) return [];
    final count = await paths.first.assetCountAsync;
    return paths.first.getAssetListRange(start: 0, end: count);
  }

  static Future<Uint8List?> thumb(AssetEntity a, {int size = 300}) async {
    final key = '${a.id}_$size';
    final hit = _cache[key];
    if (hit != null) return hit;
    final data = await a.thumbnailDataWithSize(ThumbnailSize.square(size));
    if (data != null) {
      if (_cache.length > _maxCache) {
        _cache.remove(_cache.keys.first);
      }
      _cache[key] = data;
    }
    return data;
  }

  static void preload(List<AssetEntity> list, int from, int count) {
    final end = (from + count).clamp(0, list.length);
    for (int i = from.clamp(0, list.length); i < end; i++) {
      thumb(list[i]);
    }
  }
}
