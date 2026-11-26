import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

class VaultService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'vault_pw_hash';
  static final _auth = LocalAuthentication();

  static String _hash(String pw) =>
      sha256.convert(utf8.encode('memoriq_salt_$pw')).toString();

  static Future<bool> hasPassword() async =>
      (await _storage.read(key: _key)) != null;

  static Future<void> setPassword(String pw) =>
      _storage.write(key: _key, value: _hash(pw));

  static Future<bool> checkPassword(String pw) async =>
      (await _storage.read(key: _key)) == _hash(pw);

  static Future<bool> fingerprint() async {
    try {
      final can = await _auth.canCheckBiometrics;
      if (!can) return false;
      return await _auth.authenticate(
        localizedReason: 'Unlock',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/.vault');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<List<File>> files() async {
    final d = await _dir();
    final list = d.listSync().whereType<File>().toList();
    list.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return list;
  }

  static Future<bool> hide(List<AssetEntity> assets) async {
  final d = await _dir();
  final saved = <String>[];
  for (final a in assets) {
    try {
      final bytes = await a.originBytes;
      if (bytes == null || bytes.isEmpty) continue;
      final title = await a.titleAsync;
      final ext = title.contains('.') ? title.split('.').last : 'jpg';
      final name = '${DateTime.now().microsecondsSinceEpoch}_${a.id.hashCode}.$ext';
      final out = File('${d.path}/$name');
      await out.writeAsBytes(bytes, flush: true);
      if (await out.exists() && await out.length() == bytes.length) {
        saved.add(a.id);
      }
    } catch (_) {}
  }
  if (saved.isEmpty) return false;
  await PhotoManager.editor.deleteWithIds(saved);
  return saved.length == assets.length;
  }
}
