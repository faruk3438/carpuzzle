import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

class LevelRepository {
  static final LevelRepository _instance = LevelRepository._();
  static LevelRepository get instance => _instance;
  LevelRepository._();

  final Map<String, LevelModel> _cache = {};

  static const _chapterFiles = [
    'assets/levels/chapter_1.json',
  ];

  Future<void> preloadAll() async {
    _cache.clear();
    for (final path in _chapterFiles) {
      try {
        final raw = await rootBundle.loadString(path);
        final list = jsonDecode(raw) as List<dynamic>;
        for (final data in list) {
          final level = LevelModel.fromJson(data as Map<String, dynamic>);
          if (level.level > 35) continue;
          _cache[level.id] = level;
        }
      } catch (e) {
        // Chapter dosyası yoksa atla (geliştirme aşamasında)
      }
    }
  }

  LevelModel? getLevel(String id) => _cache[id];

  List<LevelModel> getChapter(int chapter) =>
      _cache.values.where((l) => l.chapter == chapter).toList()
        ..sort((a, b) => a.level.compareTo(b.level));

  List<LevelModel> get allLevels => _cache.values.toList()
    ..sort((a, b) {
      final c = a.chapter.compareTo(b.chapter);
      return c != 0 ? c : a.level.compareTo(b.level);
    });

  int get totalLevelCount => _cache.length;

  int get totalChapters => _cache.values.map((l) => l.chapter).toSet().length;

  /// Level sonraki levelin ID'sini döndür, yoksa null
  String? nextLevelId(String currentId) {
    final current = _cache[currentId];
    if (current == null) return null;
    final chapterLevels = getChapter(current.chapter);
    final idx = chapterLevels.indexWhere((l) => l.id == currentId);
    if (idx >= 0 && idx < chapterLevels.length - 1) {
      return chapterLevels[idx + 1].id;
    }
    // Bölüm sonu → sonraki bölümün ilk leveli
    final next = getChapter(current.chapter + 1);
    return next.isNotEmpty ? next.first.id : null;
  }
}
