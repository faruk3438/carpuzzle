import 'package:shared_preferences/shared_preferences.dart';

enum DailyTaskType {
  solveWithStars,
  solveNLevels,
  useNoHints,
  comboChain,
  solveUnderPar,
}

class DailyTask {
  final DailyTaskType type;
  final String description;
  final int targetCount;
  int progress;
  bool completed;

  DailyTask({
    required this.type,
    required this.description,
    required this.targetCount,
    this.progress = 0,
    this.completed = false,
  });
}

class DailyChallengeService {
  static final DailyChallengeService _instance = DailyChallengeService._();
  static DailyChallengeService get instance => _instance;
  DailyChallengeService._();

  static const _prefKey = 'daily_challenge';
  static const _dateKey = 'daily_date';

  List<DailyTask> _tasks = [];

  List<DailyTask> get tasks => List.unmodifiable(_tasks);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    if (prefs.getString(_dateKey) != today) {
      _tasks = _buildDailyTasks(today);
      await prefs.setString(_dateKey, today);
      await _save(prefs: prefs);
    } else {
      await _loadFromPrefs(prefs);
    }
  }

  Future<void> onLevelCompleted({
    required int stars,
    required int moves,
    required int parMoves,
    required int hintsUsed,
    required int comboCount,
  }) async {
    for (final task in _tasks) {
      if (task.completed) continue;
      final updated = switch (task.type) {
        DailyTaskType.solveWithStars => stars == 3,
        DailyTaskType.solveNLevels => true,
        DailyTaskType.useNoHints => hintsUsed == 0,
        DailyTaskType.comboChain => comboCount >= 1,
        DailyTaskType.solveUnderPar => moves <= parMoves,
      };
      if (updated) {
        task.progress++;
        task.completed = task.progress >= task.targetCount;
      }
    }
    await _save();
  }

  Future<void> _loadFromPrefs(SharedPreferences prefs) async {
    final templates = _buildDailyTasks(_todayString());
    _tasks = templates.asMap().entries.map((entry) {
      final saved = prefs.getString('${_prefKey}_${entry.key}');
      if (saved == null) return entry.value;
      final parts = saved.split(',');
      return DailyTask(
        type: entry.value.type,
        description: entry.value.description,
        targetCount: entry.value.targetCount,
        progress: int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0,
        completed: (parts.elementAtOrNull(1) ?? 'false') == 'true',
      );
    }).toList();
  }

  Future<void> _save({SharedPreferences? prefs}) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      await store.setString(
        '${_prefKey}_$i',
        '${task.progress},${task.completed}',
      );
    }
  }

  List<DailyTask> _buildDailyTasks(String dateKey) {
    final seed = dateKey.hashCode.abs();
    final pool = [
      DailyTask(
        type: DailyTaskType.solveNLevels,
        description: '3 level tamamla',
        targetCount: 3,
      ),
      DailyTask(
        type: DailyTaskType.solveWithStars,
        description: '2 leveli 3 yıldızla tamamla',
        targetCount: 2,
      ),
      DailyTask(
        type: DailyTaskType.useNoHints,
        description: 'İpucu kullanmadan 1 level bitir',
        targetCount: 1,
      ),
      DailyTask(
        type: DailyTaskType.comboChain,
        description: '1 kombolu çıkış yap',
        targetCount: 1,
      ),
      DailyTask(
        type: DailyTaskType.solveUnderPar,
        description: 'Hedef hamlede 1 level bitir',
        targetCount: 1,
      ),
      DailyTask(
        type: DailyTaskType.solveNLevels,
        description: '5 level tamamla',
        targetCount: 5,
      ),
    ];

    final indices = <int>{};
    for (var i = 0; indices.length < 3; i++) {
      indices.add((seed + i * 7) % pool.length);
    }
    return indices.map((index) => pool[index]).toList();
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
