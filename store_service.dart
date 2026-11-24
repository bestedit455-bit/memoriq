import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreService {
  static Future<Set<String>> favorites() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('favs') ?? []).toSet();
  }

  static Future<void> toggleFav(String id) async {
    final p = await SharedPreferences.getInstance();
    final s = (p.getStringList('favs') ?? []).toSet();
    if (!s.remove(id)) s.add(id);
    await p.setStringList('favs', s.toList());
  }

  static Future<Directory> _trashDir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/trash');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<void> moveToTrash(List<AssetEntity> assets) async {
    final d = await _trashDir();
    final p = await SharedPreferences.getInstance();
    final rec = p.getStringList('trash') ?? [];
    for (final a in assets) {
      final f = await a.originFile;
      if (f == null) continue;
      final ext = f.path.split('.').last;
      final name = '${DateTime.now().microsecondsSinceEpoch}.$ext';
      await f.copy('${d.path}/$name');
      rec.add('$name|${DateTime.now().millisecondsSinceEpoch}');
    }
    await p.setStringList('trash', rec);
    await PhotoManager.editor.deleteWithIds(assets.map((e) => e.id).toList());
  }

  static Future<List<File>> trashFiles() async {
    await purgeOld();
    final d = await _trashDir();
    return d.listSync().whereType<File>().toList();
  }

  static Future<void> purgeOld() async {
    final p = await SharedPreferences.getInstance();
    final rec = p.getStringList('trash') ?? [];
    final d = await _trashDir();
    final keep = <String>[];
    final limit = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;
    for (final r in rec) {
      final parts = r.split('|');
      final t = int.tryParse(parts[1]) ?? 0;
      if (t < limit) {
        final f = File('${d.path}/${parts[0]}');
        if (await f.exists()) await f.delete();
      } else {
        keep.add(r);
      }
    }
    await p.setStringList('trash', keep);
  }

  static Future<void> restore(File f) async {
    final bytes = await f.readAsBytes();
    final name = f.path.split('/').last;
    final isVideo = ['mp4', 'mkv', 'mov', '3gp']
        .contains(name.split('.').last.toLowerCase());
    if (isVideo) {
      await PhotoManager.editor.saveVideo(f, title: name);
    } else {
      await PhotoManager.editor.saveImage(bytes, filename: name, title: name);
    }
    await f.delete();
    final p = await SharedPreferences.getInstance();
    final rec = p.getStringList('trash') ?? [];
    rec.removeWhere((r) => r.startsWith('$name|'));
    await p.setStringList('trash', rec);
  }

  static Future<void> deleteForever(File f) async {
    final name = f.path.split('/').last;
    if (await f.exists()) await f.delete();
    final p = await SharedPreferences.getInstance();
    final rec = p.getStringList('trash') ?? [];
    rec.removeWhere((r) => r.startsWith('$name|'));
    await p.setStringList('trash', rec);
  }
}
