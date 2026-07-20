import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../models/task_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import 'calendar_screen.dart';

class DailyPlanScreen extends StatefulWidget {
  final bool embedded;
  const DailyPlanScreen({super.key, this.embedded = false});

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  DateTime _selectedDay = DateTime.now();
  List<TaskModel> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final start = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final end = start.add(const Duration(days: 1));
    final tasks = await DatabaseService.instance.getTasksBetween(start, end);
    tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _toggle(TaskModel task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await DatabaseService.instance.upsertTask(updated);
    if (updated.isCompleted) {
      await context.read<AppState>().awardXp(15);
    }
    _load();
  }

  Future<void> _addTask() async {
    final result = await showModalBottomSheet<TaskModel>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddTaskSheet(day: _selectedDay),
    );
    if (result != null) {
      await DatabaseService.instance.upsertTask(result);
      await NotificationService.instance.scheduleTaskReminder(result);
      _load();
    }
  }

  Future<void> _delete(TaskModel task) async {
    await DatabaseService.instance.deleteTask(task.id);
    await NotificationService.instance.cancelReminder(task.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _DateStrip(selected: _selectedDay, onSelect: (d) {
          setState(() => _selectedDay = d);
          _load();
        }),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
                  ? const Center(
                      child: Text('لا توجد مهام في هذا اليوم', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tasks.length,
                      itemBuilder: (context, i) {
                        final t = _tasks[i];
                        return Dismissible(
                          key: ValueKey(t.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _delete(t),
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                                color: AppColors.danger, borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: _PlanTaskCard(task: t, onToggle: () => _toggle(t)),
                        );
                      },
                    ),
        ),
      ],
    );

    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الجدول', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_view_month),
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const CalendarScreen())),
                  ),
                  IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primary), onPressed: _addTask),
                ]),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الجدول'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addTask)],
      ),
      body: content,
    );
  }
}

class _DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _DateStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(14, (i) => DateTime(today.year, today.month, today.day - 3 + i));

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final d = days[i];
          final isSelected = d.year == selected.year && d.month == selected.month && d.day == selected.day;
          const weekdays = ['اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
          return GestureDetector(
            onTap: () => onSelect(d),
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(weekdays[d.weekday - 1],
                      style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('${d.day}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textPrimary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanTaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  const _PlanTaskCard({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final time = '${task.startTime.hour.toString().padLeft(2, '0')}:${task.startTime.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onToggle,
        leading: Icon(task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: task.isCompleted ? AppColors.accent : AppColors.textSecondary),
        title: Text(task.title,
            style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Text('$time · ${task.category.labelAr}${task.isAiGenerated ? " · بواسطة Atlas" : ""}'),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final DateTime day;
  const _AddTaskSheet({required this.day});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  TaskCategory _category = TaskCategory.other;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مهمة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'عنوان المهمة')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(_time.format(context)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<TaskCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(),
                  items: TaskCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.labelAr)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isEmpty) return;
                final start = DateTime(widget.day.year, widget.day.month, widget.day.day, _time.hour, _time.minute);
                final task = TaskModel(
                  id: const Uuid().v4(),
                  title: _titleController.text.trim(),
                  startTime: start,
                  endTime: start.add(const Duration(hours: 1)),
                  category: _category,
                );
                Navigator.pop(context, task);
              },
              child: const Text('إضافة'),
            ),
          ),
        ],
      ),
    );
  }
}
