import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math/models/point_transaction.dart';
import 'package:math/models/achievement.dart';

class UserProvider extends ChangeNotifier {
  String _username = 'Learner';
  int _totalScore = 0;
  List<PointTransaction> _history = [];
  List<Achievement> _achievements = [];

  // Streak & Themes
  int _currentStreak = 0;
  DateTime? _lastLoginDate;
  List<String> _unlockedThemes = ['Default'];
  String _currentTheme = 'Default';

  late SharedPreferences _prefs;

  String get username => _username;
  int get totalScore => _totalScore;
  List<PointTransaction> get history => _history;
  List<Achievement> get achievements => _achievements;
  int get currentStreak => _currentStreak;
  List<String> get unlockedThemes => _unlockedThemes;
  String get currentTheme => _currentTheme;

  UserProvider() {
    _loadData();
  }

  final List<Achievement> _defaultAchievements = [
    Achievement(
      id: 'score_1000',
      title: 'Novice',
      description: 'Reach 1,000 points',
      icon: '🥉',
    ),
    Achievement(
      id: 'score_3000',
      title: 'Apprentice',
      description: 'Reach 3,000 points',
      icon: '🥈',
    ),
    Achievement(
      id: 'score_5000',
      title: 'Expert',
      description: 'Reach 5,000 points',
      icon: '🥇',
    ),
    Achievement(
      id: 'score_10000',
      title: 'Master',
      description: 'Reach 10,000 points',
      icon: '💎',
    ),
    Achievement(
      id: 'score_50000',
      title: 'Grandmaster',
      description: 'Reach 50,000 points',
      icon: '🔱',
    ),
    Achievement(
      id: 'score_100000',
      title: 'Legend',
      description: 'Reach 100,000 points',
      icon: '👑',
    ),
  ];

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    _username = _prefs.getString('username') ?? 'Learner';
    _totalScore = _prefs.getInt('totalScore') ?? 0;

    final historyJson = _prefs.getString('pointHistory');
    if (historyJson != null) {
      _history = PointTransaction.decode(historyJson);
    }

    final achievementsJson = _prefs.getString('achievements');
    if (achievementsJson != null) {
      _achievements = Achievement.decode(achievementsJson);
    } else {
      _achievements = _defaultAchievements;
    }

    _currentStreak = _prefs.getInt('currentStreak') ?? 0;
    final lastLoginStr = _prefs.getString('lastLoginDate');
    if (lastLoginStr != null) {
      _lastLoginDate = DateTime.parse(lastLoginStr);
    }
    _unlockedThemes = _prefs.getStringList('unlockedThemes') ?? ['Default'];
    _currentTheme = _prefs.getString('currentTheme') ?? 'Default';

    _handleStreak();
    notifyListeners();
  }

  void _handleStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastLoginDate == null) {
      _currentStreak = 1;
      _lastLoginDate = today;
    } else {
      final lastLogin = DateTime(
        _lastLoginDate!.year,
        _lastLoginDate!.month,
        _lastLoginDate!.day,
      );
      final difference = today.difference(lastLogin).inDays;

      if (difference == 1) {
        _currentStreak++;
        _lastLoginDate = today;
        if (_currentStreak == 7) {
          addScore(300, gameName: '7-Day Streak Bonus!');
        }
      } else if (difference > 1) {
        _currentStreak = 1;
        _lastLoginDate = today;
      }
    }
    _prefs.setInt('currentStreak', _currentStreak);
    _prefs.setString('lastLoginDate', _lastLoginDate!.toIso8601String());
  }

  Future<void> setTheme(String themeId) async {
    if (_unlockedThemes.contains(themeId)) {
      _currentTheme = themeId;
      await _prefs.setString('currentTheme', _currentTheme);
      notifyListeners();
    }
  }

  Future<bool> unlockTheme(String themeId, int cost) async {
    if (_totalScore >= cost && !_unlockedThemes.contains(themeId)) {
      await addScore(-cost, gameName: 'Unlocked Theme: $themeId');
      _unlockedThemes.add(themeId);
      await _prefs.setStringList('unlockedThemes', _unlockedThemes);
      _currentTheme = themeId;
      await _prefs.setString('currentTheme', _currentTheme);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> updateUsername(String name) async {
    if (name.trim().isEmpty) return;
    _username = name.trim();
    await _prefs.setString('username', _username);
    notifyListeners();
  }

  Future<void> addScore(int points, {String? gameName}) async {
    _totalScore = _totalScore + points;
    await _prefs.setInt('totalScore', _totalScore);

    if (gameName != null) {
      await addHistoryEntry(points, gameName);
      _checkAchievements(points, gameName);
    } else {
      notifyListeners();
    }
  }

  void _checkAchievements(int points, String gameName) {
    bool updated = false;

    void unlock(String id) {
      final index = _achievements.indexWhere(
        (a) => a.id == id && !a.isUnlocked,
      );
      if (index != -1) {
        _achievements[index] = _achievements[index].copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        updated = true;
      }
    }

    if (_totalScore >= 1000) unlock('score_1000');
    if (_totalScore >= 3000) unlock('score_3000');
    if (_totalScore >= 5000) unlock('score_5000');
    if (_totalScore >= 10000) unlock('score_10000');
    if (_totalScore >= 50000) unlock('score_50000');
    if (_totalScore >= 100000) unlock('score_100000');

    if (updated) {
      _prefs.setString('achievements', Achievement.encode(_achievements));
      notifyListeners();
    }
  }

  Future<void> addHistoryEntry(int points, String gameName) async {
    final transaction = PointTransaction(
      date: DateTime.now(),
      gameName: gameName,
      points: points,
    );
    _history.insert(0, transaction);
    if (_history.length > 100) _history = _history.sublist(0, 100);
    await _prefs.setString('pointHistory', PointTransaction.encode(_history));
    notifyListeners();
  }

  Future<void> resetData() async {
    _username = 'Learner';
    _totalScore = 0;
    _history = [];
    _achievements = _defaultAchievements;
    _currentStreak = 0;
    _unlockedThemes = ['Default'];
    _currentTheme = 'Default';
    await _prefs.clear();
    notifyListeners();
  }
}
