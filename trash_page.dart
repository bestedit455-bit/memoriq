import 'dart:io';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'store_service.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<File> _files = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final f = await StoreService.trashFiles();
    if (mounted) setState(() => _files = f);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash (30 days)',
            style: TextStyle(color: AppColors.gold)),
      ),
      body: _files.isEmpty
          ? const Center(
              child: Text('Trash is empty',
                  style: TextStyle(color: AppColors.textSecondary)))
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: _files.length,
              itemBuilder: (context, i) {
                final f = _files[i];
                return GestureDetector(
                  onTap: () async {
                    await StoreService.restore(f);
                    _load();
                  },
                  onLongPress: () async {
                    await StoreService.deleteForever(f);
                    _load();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      f,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.surface),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
