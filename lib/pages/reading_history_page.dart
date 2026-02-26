import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/theme/app_theme.dart';
import 'package:math/models/reading_record.dart';
import 'package:intl/intl.dart';
import 'package:math/widgets/math_dialog.dart';

class ReadingHistoryPage extends StatelessWidget {
  const ReadingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final themeId = user.currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;
    final history = user.readingHistory;

    // Grouping logic: Year -> Month -> Week
    final grouped = _groupRecords(history);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('📚 Reading Journey'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookRegistrationDialog(context),
        backgroundColor: Colors.orangeAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Book',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [config.gradientStart, config.gradientEnd],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildWeeklyStatusCard(context, user),
                Expanded(
                  child: history.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final monthGroup = grouped[index];
                            return _buildMonthSection(context, monthGroup);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatusCard(BuildContext context, UserProvider user) {
    bool hasRead = user.hasReadThisWeek;
    final color = hasRead ? Colors.lightGreenAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              hasRead ? '✅' : '⏳',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasRead ? 'Goal Accomplished!' : 'Weekly Goal Pending',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasRead
                      ? 'You have read ${user.weeklyBookTitles.length} book(s) this week.'
                      : 'Read at least one book this week to avoid the penalty!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBookRegistrationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => MathDialog(
        title: 'REGISTER BOOK',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Book Title',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        onConfirm: () {
          if (passwordController.text == '9891') {
            if (titleController.text.trim().isNotEmpty) {
              context.read<UserProvider>().addBookRead(titleController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Book registered successfully!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a book title.')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect password.')),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📚', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'No books recorded yet.',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const Text(
            'Start your reading journey today!',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(BuildContext context, _MonthGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Text(
            group.monthName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...group.weeks.map((week) => _buildWeekCard(context, week)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildWeekCard(BuildContext context, _WeekGroup week) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week ${week.weekOfMonth}',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${week.records.length} book${week.records.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: week.records.map((r) => _buildBookItem(r)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem(ReadingRecord record) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.book, color: Colors.orangeAccent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd').format(record.date),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_MonthGroup> _groupRecords(List<ReadingRecord> records) {
    final Map<String, _MonthGroup> monthGroups = {};

    for (var record in records) {
      final monthKey = DateFormat('yyyy-MM').format(record.date);
      final monthName = DateFormat('MMMM yyyy').format(record.date);

      final group = monthGroups.putIfAbsent(
        monthKey,
        () => _MonthGroup(monthKey, monthName),
      );

      // Determine week of month (simple calculation)
      int weekOfMonth = ((record.date.day - 1) / 7).floor() + 1;

      final weekGroup = group.weeks.firstWhere(
        (w) => w.weekOfMonth == weekOfMonth,
        orElse: () {
          final nw = _WeekGroup(weekOfMonth);
          group.weeks.add(nw);
          return nw;
        },
      );

      weekGroup.records.add(record);
    }

    final result = monthGroups.values.toList();
    result.sort((a, b) => b.monthKey.compareTo(a.monthKey));
    for (var m in result) {
      m.weeks.sort((a, b) => b.weekOfMonth.compareTo(a.weekOfMonth));
    }
    return result;
  }
}

class _MonthGroup {
  final String monthKey;
  final String monthName;
  final List<_WeekGroup> weeks = [];

  _MonthGroup(this.monthKey, this.monthName);
}

class _WeekGroup {
  final int weekOfMonth;
  final List<ReadingRecord> records = [];

  _WeekGroup(this.weekOfMonth);
}
