import 'dart:io';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'glass.dart';
import 'vault_service.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  final _pw = TextEditingController();
  bool _unlocked = false;
  bool _firstTime = false;
  String _error = '';
  List<File> _files = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final has = await VaultService.hasPassword();
    setState(() => _firstTime = !has);
    if (has) {
      final ok = await VaultService.fingerprint();
      if (ok) await _open();
    }
  }

  Future<void> _open() async {
    final f = await VaultService.files();
    if (!mounted) return;
    setState(() {
      _files = f;
      _unlocked = true;
    });
  }

  Future<void> _submit() async {
    final text = _pw.text.trim();
    if (text.length < 4) {
      setState(() => _error = 'Minimum 4 characters');
      return;
    }
    if (_firstTime) {
      await VaultService.setPassword(text);
      await _open();
    } else if (await VaultService.checkPassword(text)) {
      await _open();
    } else {
      setState(() => _error = 'Wrong password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _unlocked ? _grid() : _lock(),
    );
  }

  Widget _lock() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LiquidGlass(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _firstTime ? 'Create password' : 'Enter password',
                style: const TextStyle(
                    color: AppColors.gold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pw,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gold),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('OK'),
              ),
              if (!_firstTime)
                TextButton(
                  onPressed: () async {
                    if (await VaultService.fingerprint()) await _open();
                  },
                  child: const Text('Use fingerprint'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    if (_files.isEmpty) {
      return const Center(
        child: Text('Empty',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _files.length,
      itemBuilder: (context, i) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          _files[i],
          fit: BoxFit.cover,
          cacheWidth: 300,
          errorBuilder: (_, __, ___) =>
              Container(color: AppColors.surface),
        ),
      ),
    );
  }
}
