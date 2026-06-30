import 'package:shared_preferences/shared_preferences.dart';

/// Stores only durable level progress used by the live game.
class ProgressService {
  static final ProgressService _instance = ProgressService._();
  static ProgressService get instance => _instance;
  ProgressService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveStars(String levelId, int stars) async {
    final key = 'stars_$levelId';
    final current = _prefs.getInt(key) ?? 0;
    if (stars > current) await _prefs.setInt(key, stars);
  }

  int getStars(String levelId) => _prefs.getInt('stars_$levelId') ?? 0;

  bool isLevelCompleted(String levelId) => getStars(levelId) > 0;

  int chapterStars(int chapter, List<String> levelIds) =>
      levelIds.fold(0, (sum, id) => sum + getStars(id));

  Future<void> saveHighScore(String levelId, int score) async {
    final key = 'score_$levelId';
    final current = _prefs.getInt(key) ?? 0;
    if (score > current) await _prefs.setInt(key, score);
  }

  int getHighScore(String levelId) => _prefs.getInt('score_$levelId') ?? 0;

  Future<void> saveBestMoves(String levelId, int moves) async {
    final key = 'moves_$levelId';
    final current = _prefs.getInt(key);
    if (current == null || moves < current) await _prefs.setInt(key, moves);
  }

  int? getBestMoves(String levelId) => _prefs.getInt('moves_$levelId');

  Future<void> clearAll() => _prefs.clear();
}
