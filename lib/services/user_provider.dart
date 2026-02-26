import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:math/models/point_transaction.dart';
import 'package:math/models/achievement.dart';
import 'package:math/models/fx_transaction.dart';
import 'package:math/models/reading_record.dart';

class UserProvider extends ChangeNotifier {
  String _username = 'Learner';
  int _totalScore = 0;
  int _diamonds = 0;
  int _diamondPrice = 100;
  String _currentTheme = 'Default';
  String _currentAvatar = '👨‍🚀';
  bool _isTtsEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isAuraEnabled = true;
  int _boughtMultiplier = 1;
  String _multiplierDate = '';
  String _lastMonthlyBonusDate = '';

  final List<String> _weeklyBookTitles = [];
  final List<PointTransaction> _pointHistory = [];
  final List<Achievement> _achievements = [];
  List<ReadingRecord> _readingHistory = [];
  List<String> _unlockedThemes = ['Default'];
  List<String> _unlockedAvatars = ['👨‍🚀', '👤'];
  String _lastCheckedWeekId = '';

  // Currency Exchange Data
  Map<String, double> _currencyHoldings = {
    'USD': 0.0,
    'EUR': 0.0,
    'JPY': 0.0,
    'GBP': 0.0,
    'CNY': 0.0,
  };
  Map<String, int> _currencyPrices = {
    'USD': 1400,
    'EUR': 1500,
    'JPY': 10,
    'GBP': 1800,
    'CNY': 200,
  };
  Map<String, List<int>> _currencyHistory = {};
  Map<String, List<FxTransaction>> _fxHistory = {};
  String _lastFxUpdate = '';

  // Streak & Themes
  int _currentStreak = 0;
  DateTime? _lastLoginDate;
  late SharedPreferences _prefs;

  String get username => _username;
  int get totalScore => _totalScore;
  int get diamonds => _diamonds;
  int get diamondPrice => _diamondPrice;
  int get diamondMarketPrice => _diamondPrice;
  String get currentTheme => _currentTheme;
  String get currentAvatar => _currentAvatar;
  bool get isTtsEnabled => _isTtsEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isAuraEnabled => _isAuraEnabled;
  int get currentStreak => _currentStreak;
  List<PointTransaction> get pointHistory => _pointHistory;
  List<PointTransaction> get history => _pointHistory; // Alias
  List<Achievement> get achievements => _achievements;
  List<String> get weeklyBookTitles => _weeklyBookTitles;
  List<ReadingRecord> get readingHistory => _readingHistory;
  List<String> get unlockedThemes => _unlockedThemes;
  List<String> get unlockedAvatars => _unlockedAvatars;
  bool get hasReadThisWeek => _weeklyBookTitles.isNotEmpty;

  double get pointMultiplier {
    _checkMultiplierExpiry();
    return _boughtMultiplier.toDouble();
  }

  Map<String, double> get currencyHoldings => _currencyHoldings;
  Map<String, int> get currencyPrices => _currencyPrices;
  Map<String, List<int>> get currencyHistory => _currencyHistory;
  Map<String, List<FxTransaction>> get fxHistory => _fxHistory;

  // Bid/Ask Spread: Sell price is 95% of buy price
  int getSellPrice(String code) {
    int buyPrice = _currencyPrices[code] ?? 0;
    return (buyPrice * 0.95).round();
  }

  Color get highestAchievementColor {
    if (_totalScore >= 100000) return Colors.purpleAccent; // Legend
    if (_totalScore >= 70000) return Colors.cyanAccent; // Grandmaster
    if (_totalScore >= 50000) return Colors.orangeAccent; // Master
    if (_totalScore >= 30000) return const Color(0xFFE5E4E2); // Platinum
    if (_totalScore >= 10000) return Colors.amberAccent; // Gold
    if (_totalScore >= 5000) return const Color(0xFFC0C0C0); // Silver
    if (_totalScore >= 1000) return const Color(0xFFCD7F32); // Bronze
    return Colors.grey;
  }

  UserProvider() {
    _initAchievements();
    _loadData();
  }

  void _initAchievements() {
    if (_achievements.isEmpty) {
      _achievements.addAll([
        Achievement(
          id: 'bronze',
          title: 'Bronze',
          description: 'Reach 1,000 points',
          icon: '🥉',
          threshold: 1000,
        ),
        Achievement(
          id: 'silver',
          title: 'Silver',
          description: 'Reach 5,000 points',
          icon: '🥈',
          threshold: 5000,
        ),
        Achievement(
          id: 'gold',
          title: 'Gold',
          description: 'Reach 10,000 points',
          icon: '🥇',
          threshold: 10000,
        ),
        Achievement(
          id: 'platinum',
          title: 'Platinum',
          description: 'Reach 30,000 points',
          icon: '💎',
          threshold: 30000,
        ),
        Achievement(
          id: 'master',
          title: 'Master',
          description: 'Reach 50,000 points',
          icon: '👑',
          threshold: 50000,
        ),
        Achievement(
          id: 'grandmaster',
          title: 'Grandmaster',
          description: 'Reach 70,000 points',
          icon: '🌌',
          threshold: 70000,
        ),
        Achievement(
          id: 'legend',
          title: 'Legend',
          description: 'Reach 100,000 points',
          icon: '✨',
          threshold: 100000,
        ),
      ]);
    }
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    _username = _prefs.getString('username') ?? 'Learner';
    _totalScore = _prefs.getInt('totalScore') ?? 0;
    _diamonds = _prefs.getInt('diamonds') ?? 0;
    _currentTheme = _prefs.getString('currentTheme') ?? 'Default';
    _currentAvatar = _prefs.getString('currentAvatar') ?? '👨‍🚀';
    _isTtsEnabled = _prefs.getBool('isTtsEnabled') ?? true;
    _isVibrationEnabled = _prefs.getBool('isVibrationEnabled') ?? true;
    _isAuraEnabled = _prefs.getBool('isAuraEnabled') ?? true;
    _boughtMultiplier = _prefs.getInt('boughtMultiplier') ?? 1;
    _multiplierDate = _prefs.getString('multiplierDate') ?? '';
    _weeklyBookTitles.addAll(_prefs.getStringList('weeklyBookTitles') ?? []);
    _unlockedAvatars =
        _prefs.getStringList('unlockedAvatars') ?? ['👨‍🚀', '👤'];
    _lastMonthlyBonusDate = _prefs.getString('lastMonthlyBonusDate') ?? '';

    final historyList = _prefs.getStringList('pointHistory') ?? [];
    for (var item in historyList) {
      _pointHistory.add(PointTransaction.fromJson(jsonDecode(item)));
    }

    final achievementList = _prefs.getStringList('achievements') ?? [];
    if (achievementList.isNotEmpty) {
      _achievements.clear();
      for (var item in achievementList) {
        _achievements.add(Achievement.fromMap(jsonDecode(item)));
      }
    }

    final readingJson = _prefs.getString('readingHistory');
    if (readingJson != null) {
      _readingHistory = (jsonDecode(readingJson) as List)
          .map((e) => ReadingRecord.fromJson(e))
          .toList();
    }
    _lastCheckedWeekId = _prefs.getString('lastCheckedWeekId') ?? '';

    _loadFxData();
    _updateDiamondPrice();
    _checkWeeklyReadingPenalty();
    _checkMultiplierExpiry();

    // Streak logic
    final lastLoginStr = _prefs.getString('lastLoginDate');
    final now = DateTime.now();
    bool awardedDaily = false;

    if (lastLoginStr != null) {
      _lastLoginDate = DateTime.parse(lastLoginStr);
      final diff = now.difference(_lastLoginDate!).inDays;
      if (diff == 1) {
        _currentStreak = (_prefs.getInt('currentStreak') ?? 0) + 1;
        awardedDaily = true;
      } else if (diff > 1) {
        _currentStreak = 1;
        awardedDaily = true;
      } else {
        _currentStreak = _prefs.getInt('currentStreak') ?? 1;
      }
    } else {
      _currentStreak = 1;
      awardedDaily = true;
    }

    if (awardedDaily) {
      int bonus = 100;
      if (_currentStreak >= 30)
        bonus = 300;
      else if (_currentStreak >= 15)
        bonus = 200;

      addScore(bonus, gameName: 'Daily Attendance Bonus');
    }

    // Monthly bonus
    final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    if (_lastMonthlyBonusDate != currentMonth) {
      _lastMonthlyBonusDate = currentMonth;
      _prefs.setString('lastMonthlyBonusDate', _lastMonthlyBonusDate);
      addScore(300, gameName: 'Monthly Attendance Bonus');
    }

    _lastLoginDate = now;
    _prefs.setString('lastLoginDate', _lastLoginDate!.toIso8601String());
    _prefs.setInt('currentStreak', _currentStreak);

    _checkAchievements();
    notifyListeners();
  }

  void _checkMultiplierExpiry() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_multiplierDate != today) {
      _boughtMultiplier = 1;
      _multiplierDate = today;
      _prefs.setInt('boughtMultiplier', 1);
      _prefs.setString('multiplierDate', today);
    }
  }

  void _checkWeeklyReadingPenalty() {
    final now = DateTime.now();
    final weekId = "${now.year}-W${((now.day + 7 - now.weekday) / 7).ceil()}";
    if (_lastCheckedWeekId != weekId) {
      if (_lastCheckedWeekId.isNotEmpty && _weeklyBookTitles.isEmpty) {
        addScore(-1500, gameName: 'Weekly Reading Penalty');
      }
      _weeklyBookTitles.clear();
      _lastCheckedWeekId = weekId;
      _prefs.setStringList('weeklyBookTitles', _weeklyBookTitles);
      _prefs.setString('lastCheckedWeekId', _lastCheckedWeekId);
    }
  }

  void _loadFxData() {
    final holdingsJson = _prefs.getString('currencyHoldings');
    if (holdingsJson != null) {
      final decoded = jsonDecode(holdingsJson) as Map<String, dynamic>;
      _currencyHoldings = decoded.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
    }

    final historyJson = _prefs.getString('currencyHistory');
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
      _currencyHistory = decoded.map((k, v) => MapEntry(k, List<int>.from(v)));
    } else {
      // Seed initial history if empty
      _currencyHistory = {
        'USD': [1350, 1370, 1400, 1380, 1390, 1420, 1400],
        'EUR': [1450, 1460, 1480, 1470, 1490, 1510, 1500],
        'JPY': [9, 10, 11, 10, 9, 10, 10],
        'GBP': [1750, 1770, 1800, 1780, 1810, 1830, 1800],
        'CNY': [190, 195, 200, 198, 202, 205, 200],
      };
    }

    final fxHistoryJson = _prefs.getString('fxHistory');
    if (fxHistoryJson != null) {
      final decoded = jsonDecode(fxHistoryJson) as Map<String, dynamic>;
      _fxHistory = decoded.map(
        (k, v) => MapEntry(
          k,
          (v as List).map((e) => FxTransaction.fromJson(e)).toList(),
        ),
      );
    }
    _lastFxUpdate = _prefs.getString('lastFxUpdate') ?? '';
    _updateCurrencyPrices();
  }

  void _updateCurrencyPrices() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_lastFxUpdate != today) {
      final random = math.Random();
      final newPrices = {
        'USD': (1350 + random.nextInt(100)),
        'EUR': (1450 + random.nextInt(100)),
        'JPY': (9 + random.nextInt(3)),
        'GBP': (1750 + random.nextInt(100)),
        'CNY': (190 + random.nextInt(20)),
      };

      _currencyPrices = newPrices;

      // Update history
      _currencyPrices.forEach((code, price) {
        final history = _currencyHistory[code] ?? [];
        history.add(price);
        if (history.length > 14) history.removeAt(0); // Keep 14 days
        _currencyHistory[code] = history;
      });

      _lastFxUpdate = today;
      _prefs.setString('lastFxUpdate', _lastFxUpdate);
      _prefs.setString('currencyHistory', jsonEncode(_currencyHistory));
    }
  }

  Future<void> _saveFxData() async {
    await _prefs.setString('currencyHoldings', jsonEncode(_currencyHoldings));
    // Manually convert Map<String, List<FxTransaction>> to JSON compatible format
    final historyJson = _fxHistory.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    );
    await _prefs.setString('fxHistory', jsonEncode(historyJson));
  }

  // Updated to accept integer amounts only as per user request
  Future<bool> buyCurrency(String code, double amount) async {
    if (amount != amount.toInt().toDouble()) return false; // Enforce integer

    int price = _currencyPrices[code] ?? 0;
    int cost = (price * amount).round();
    if (_totalScore >= cost) {
      await addScore(-cost, gameName: 'Bought ${amount.toInt()} $code');
      _currencyHoldings[code] = (_currencyHoldings[code] ?? 0) + amount;

      // Record History
      final tx = FxTransaction(
        type: 'BUY',
        amount: amount,
        pricePerUnit: price,
        totalPoints: cost,
        date: DateTime.now(),
      );
      _fxHistory[code] = (_fxHistory[code] ?? [])..add(tx);

      await _saveFxData();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Updated to use bid price (95% value) and integer amounts
  Future<bool> sellCurrency(String code, double amount) async {
    if (amount != amount.toInt().toDouble()) return false; // Enforce integer

    double holding = _currencyHoldings[code] ?? 0;
    if (holding >= amount) {
      int sellPrice = getSellPrice(code);
      int gain = (sellPrice * amount).round();
      await addScore(
        gain,
        gameName: 'Sold ${amount.toInt()} $code',
        bypassMultiplier: true,
      );
      _currencyHoldings[code] = holding - amount;

      // Record History
      final tx = FxTransaction(
        type: 'SELL',
        amount: amount,
        pricePerUnit: sellPrice,
        totalPoints: gain,
        date: DateTime.now(),
      );
      _fxHistory[code] = (_fxHistory[code] ?? [])..add(tx);

      await _saveFxData();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> addBookRead(String title) async {
    if (title.trim().isEmpty) return;
    String trimmed = title.trim();
    _weeklyBookTitles.add(trimmed);
    _readingHistory.add(ReadingRecord(title: trimmed, date: DateTime.now()));
    await _prefs.setStringList('weeklyBookTitles', _weeklyBookTitles);
    await _prefs.setString(
      'readingHistory',
      jsonEncode(_readingHistory.map((e) => e.toJson()).toList()),
    );
    _checkAchievements();
    notifyListeners();
  }

  void _updateDiamondPrice() {
    _diamondPrice = 90 + math.Random().nextInt(21);
    notifyListeners();
  }

  Future<bool> exchangeDiamondsToPoints(int units) async {
    int total = units * 100;
    if (_diamonds >= total) {
      int gain = units * _diamondPrice;
      await addScore(
        gain,
        gameName: 'Exchanged $total Diamonds',
        bypassMultiplier: true,
      );
      _diamonds -= total;
      _prefs.setInt('diamonds', _diamonds);
      return true;
    }
    return false;
  }

  Future<bool> unlockTheme(String themeId, int cost) async {
    if (_totalScore >= cost && !_unlockedThemes.contains(themeId)) {
      await addScore(-cost, gameName: 'Unlocked Theme: $themeId');
      _unlockedThemes.add(themeId);
      _prefs.setStringList('unlockedThemes', _unlockedThemes);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> unlockAvatar(String emoji, int cost) async {
    if (_totalScore >= cost && !_unlockedAvatars.contains(emoji)) {
      await addScore(-cost, gameName: 'Unlocked Avatar: $emoji');
      _unlockedAvatars.add(emoji);
      _prefs.setStringList('unlockedAvatars', _unlockedAvatars);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> purchaseMultiplier(int multiplier, int cost) async {
    if (_totalScore >= cost) {
      await addScore(-cost, gameName: 'Purchased ${multiplier}x Boost');
      _boughtMultiplier = multiplier;
      _multiplierDate = DateTime.now().toIso8601String().split('T')[0];
      _prefs.setInt('boughtMultiplier', _boughtMultiplier);
      _prefs.setString('multiplierDate', _multiplierDate);
      notifyListeners();
      return true;
    }
    return false;
  }

  void setAvatar(String emoji) {
    if (_unlockedAvatars.contains(emoji)) {
      _currentAvatar = emoji;
      _prefs.setString('currentAvatar', emoji);
      notifyListeners();
    }
  }

  void setTheme(String theme) {
    if (_unlockedThemes.contains(theme)) {
      _currentTheme = theme;
      _prefs.setString('currentTheme', theme);
      notifyListeners();
    }
  }

  void setTtsEnabled(bool v) {
    _isTtsEnabled = v;
    _prefs.setBool('isTtsEnabled', v);
    notifyListeners();
  }

  void setVibrationEnabled(bool v) {
    _isVibrationEnabled = v;
    _prefs.setBool('isVibrationEnabled', v);
    notifyListeners();
  }

  void setUsername(String n) {
    _username = n;
    _prefs.setString('username', n);
    notifyListeners();
  }

  void updateUsername(String n) => setUsername(n); // Alias

  Future<void> addScore(
    int p, {
    String? gameName,
    bool bypassMultiplier = false,
  }) async {
    int finalP = p;
    if (p > 0 && !bypassMultiplier) finalP = (p * pointMultiplier).round();
    _totalScore += finalP;
    if (_totalScore < 0) _totalScore = 0;
    _prefs.setInt('totalScore', _totalScore);
    if (gameName != null) {
      await addHistoryEntry(finalP, gameName);
      _checkAchievements();
    }
    notifyListeners();
  }

  Future<void> addDiamonds(int a) async {
    _diamonds += a;
    _prefs.setInt('diamonds', _diamonds);
    notifyListeners();
  }

  Future<bool> useDiamonds(int a) async {
    if (_diamonds >= a) {
      _diamonds -= a;
      _prefs.setInt('diamonds', _diamonds);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> addHistoryEntry(int p, String g) async {
    final entry = PointTransaction(
      points: p,
      gameName: g,
      date: DateTime.now(),
    );
    _pointHistory.insert(0, entry);
    if (_pointHistory.length > 50) _pointHistory.removeLast();
    await _prefs.setStringList(
      'pointHistory',
      _pointHistory.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  void _checkAchievements() {
    bool changed = false;
    for (int i = 0; i < _achievements.length; i++) {
      if (_achievements[i].isUnlocked) continue;
      if (_totalScore >= _achievements[i].threshold) {
        _achievements[i] = _achievements[i].copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        changed = true;
      }
    }
    if (changed) {
      _prefs.setStringList(
        'achievements',
        _achievements.map((e) => jsonEncode(e.toMap())).toList(),
      );
      notifyListeners();
    }
  }

  Future<void> resetData() async {
    _totalScore = 0;
    _diamonds = 0;
    _currentTheme = 'Default';
    _currentStreak = 1;
    _pointHistory.clear();
    for (int i = 0; i < _achievements.length; i++)
      _achievements[i] = _achievements[i].copyWith(isUnlocked: false);
    _weeklyBookTitles.clear();
    _readingHistory = [];
    _lastCheckedWeekId = '';
    _currencyHoldings = _currencyHoldings.map((k, v) => MapEntry(k, 0.0));
    _lastFxUpdate = '';
    _unlockedThemes = ['Default'];
    _unlockedAvatars = ['👨‍🚀', '👤'];
    await _prefs.clear();
    notifyListeners();
  }
}
