import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/task_model.dart';
import '../../services/database_service.dart';

/// A lightweight month-grid calendar showing task density per day.
/// Deliberately avoids adding a third-party calendar package to keep the
/// project's dependency surface (and build risk) small.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<int, List<TaskModel>> _tasksByDay = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final start = DateTime(_month.year, _month.month, 1);
    final end = DateTime(_month.year, _month.month + 1, 1);
    final tasks = await DatabaseService.instance.getTasksBetween(start, end);

    final map = <int, List<TaskModel>>{};
    for (final t in tasks) {
      map.putIfAbsent(t.startTime.day, () => []).add(t);
    }
    if (!mounted) return;
    setState(() {
      _tasksByDay = map;
      _loading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday; // 1=Mon
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = firstWeekday - 1;
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(-1)),
            Text('${monthNames[_month.month - 1]} ${_month.year}'),
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(1)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: leadingBlanks + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) return const SizedBox();
                  final day = index - leadingBlanks + 1;
                  final tasks = _tasksByDay[day] ?? [];
                  final isToday = DateTime.now().year == _month.year &&
                      DateTime.now().month == _month.month &&
                      DateTime.now().day == day;

                  return Container(
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isToday ? Colors.white : AppColors.textPrimary)),
                        if (tasks.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isToday ? Colors.white : AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
