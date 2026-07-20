import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_state.dart';
import '../../ai/atlas_brain.dart';
import '../../models/task_model.dart';
import '../../services/database_service.dart';
import '../assistant/atlas_chat_screen.dart';
import '../planner/daily_plan_screen.dart';
import '../habits/habits_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final _screens = const [
    _HomeDashboard(),
    DailyPlanScreen(embedded: true),
    AtlasChatScreen(embedded: true),
    HabitsScreen(embedded: true),
    ProgressScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_tab]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'الجدول'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: 'Atlas'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'العادات'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'الإحصائيات'),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatefulWidget {
  const _HomeDashboard();

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  final _brain = AtlasBrain();
  AtlasBriefing? _briefing;
  List<TaskModel> _todayTasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final briefing = await _brain.dailyBriefing();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final tasks = await DatabaseService.instance.getTasksBetween(startOfDay, endOfDay);
    tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    if (!mounted) return;
    setState(() {
      _briefing = briefing;
      _todayTasks = tasks;
      _loading = false;
    });
  }

  Future<void> _toggleTask(TaskModel task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await DatabaseService.instance.upsertTask(updated);
    if (updated.isCompleted) {
      await context.read<AppState>().awardXp(15);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;

    if (_loading || user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحبًا، ${user.name} 👋',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Lv.${user.level} · ${user.rankTitle}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProductivityCard(rate: _briefing!.productivityRate, level: user.level, xp: user.xp,
              xpNeeded: user.xpToNextLevel()),
          const SizedBox(height: 20),
          const Text('جدول اليوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_todayTasks.isEmpty)
            const _EmptyTodayCard()
          else
            ..._todayTasks.map((t) => _TaskTile(task: t, onToggle: () => _toggleTask(t))),
          const SizedBox(height: 20),
          const Text('نصائح Atlas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._briefing!.tips.map((tip) => _TipCard(text: tip)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ProductivityCard extends StatelessWidget {
  final double rate;
  final int level;
  final int xp;
  final int xpNeeded;

  const _ProductivityCard({required this.rate, required this.level, required this.xp, required this.xpNeeded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إنتاجية اليوم', style: TextStyle(color: Colors.white70)),
              Text('${(rate * 100).round()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate.clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('$xp / $xpNeeded XP', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTodayCard extends StatelessWidget {
  const _EmptyTodayCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.event_available, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('لا توجد مهام اليوم. تحدث مع Atlas ليضع لك خطة!',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  const _TaskTile({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final timeLabel = '${task.startTime.hour.toString().padLeft(2, '0')}:${task.startTime.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onToggle,
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: task.isCompleted ? AppColors.accent : AppColors.textSecondary,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text('$timeLabel · ${task.category.labelAr}'),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  const _TipCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
