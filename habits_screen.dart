import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/app_state.dart';
import '../../models/habit_model.dart';
import '../../services/database_service.dart';

class HabitsScreen extends StatefulWidget {
  final bool embedded;
  const HabitsScreen({super.key, this.embedded = false});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<HabitModel> _habits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await DatabaseService.instance.getAllHabits();
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _loading = false;
    });
  }

  Future<void> _toggleToday(HabitModel habit) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = [...habit.completedDates];

    if (habit.completedToday) {
      dates.removeWhere((d) => d.year == today.year && d.month == today.month && d.day == today.day);
    } else {
      dates.add(today);
      await context.read<AppState>().awardXp(8);
    }

    final updated = habit.copyWith(completedDates: dates);
    await DatabaseService.instance.upsertHabit(updated);
    _load();
  }

  Future<void> _addHabit() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('عادة جديدة'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'مثال: قراءة 20 دقيقة')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      await DatabaseService.instance.upsertHabit(HabitModel(id: const Uuid().v4(), title: title));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : _habits.isEmpty
            ? const Center(
                child: Text('لا توجد عادات بعد — أضف أول عادة لك', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _habits.length,
                itemBuilder: (context, i) {
                  final h = _habits[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () => _toggleToday(h),
                      leading: CircleAvatar(
                        backgroundColor: h.completedToday ? AppColors.accent : AppColors.surfaceVariant,
                        child: Text(h.icon),
                      ),
                      title: Text(h.title),
                      subtitle: Text('🔥 ${h.currentStreak} يوم متتالي'),
                      trailing: Icon(
                        h.completedToday ? Icons.check_circle : Icons.circle_outlined,
                        color: h.completedToday ? AppColors.accent : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              );

    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('العادات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primary), onPressed: _addHabit),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('العادات'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _addHabit),
      ]),
      body: content,
    );
  }
}
