import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math/models/point_transaction.dart';

class UserProvider extends ChangeNotifier {
  String _username = 'Learner';
  int _totalScore = 0;
  List<PointTransaction> _history = [];
  late SharedPreferences _prefs;

  String get username => _username;
  int get totalScore => _totalScore;
  List<PointTransaction> get history => _history;

  UserProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    _username = _prefs.getString('username') ?? 'Learner';
    _totalScore = _prefs.getInt('totalScore') ?? 0;

    final historyJson = _prefs.getString('pointHistory');
    if (historyJson != null) {
      _history = PointTransaction.decode(historyJson);
    }

    notifyListeners();
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
    } else {
      notifyListeners();
    }
  }

  Future<void> addHistoryEntry(int points, String gameName) async {
    final transaction = PointTransaction(
      date: DateTime.now(),
      gameName: gameName,
      points: points,
    );
    _history.insert(0, transaction); // Most recent first
    if (_history.length > 100)
      _history = _history.sublist(0, 100); // Keep last 100
    await _prefs.setString('pointHistory', PointTransaction.encode(_history));
    notifyListeners();
  }

  Future<void> resetData() async {
    _username = 'Learner';
    _totalScore = 0;
    _history = [];
    await _prefs.clear();
    notifyListeners();
  }
}
