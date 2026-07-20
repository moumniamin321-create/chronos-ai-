import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_state.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _goalController = TextEditingController();
  final List<String> _goals = [];
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);

  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _pageController.animateToPage(_step,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final user = await AuthService.instance.createLocalProfile(
      name: _nameController.text.trim().isEmpty ? 'صديقي' : _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 18,
      goals: _goals,
      wakeTime:
          '${_wakeTime.hour.toString().padLeft(2, '0')}:${_wakeTime.minute.toString().padLeft(2, '0')}',
      sleepTime:
          '${_sleepTime.hour.toString().padLeft(2, '0')}:${_sleepTime.minute.toString().padLeft(2, '0')}',
    );
    if (!mounted) return;
    await context.read<AppState>().setUser(user);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _Header(step: _step),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _NameAgeStep(nameController: _nameController, ageController: _ageController),
                  _GoalsStep(
                    goalController: _goalController,
                    goals: _goals,
                    onAdd: (g) => setState(() => _goals.add(g)),
                    onRemove: (g) => setState(() => _goals.remove(g)),
                  ),
                  _SleepStep(
                    wakeTime: _wakeTime,
                    sleepTime: _sleepTime,
                    onWakeChanged: (t) => setState(() => _wakeTime = t),
                    onSleepChanged: (t) => setState(() => _sleepTime = t),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _next,
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_step < 2 ? 'التالي' : 'ابدأ رحلتي مع Atlas'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int step;
  const _Header({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= step;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NameAgeStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController ageController;
  const _NameAgeStep({required this.nameController, required this.ageController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.heroGradient.createShader(bounds),
            child: const Text('Chronos AI',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          const Text('لنتعرف عليك أولاً', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 32),
          TextField(controller: nameController, decoration: const InputDecoration(hintText: 'اسمك')),
          const SizedBox(height: 16),
          TextField(
            controller: ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'عمرك'),
          ),
        ],
      ),
    );
  }
}

class _GoalsStep extends StatelessWidget {
  final TextEditingController goalController;
  final List<String> goals;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  const _GoalsStep({
    required this.goalController,
    required this.goals,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('ما هي أهدافك؟', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('أضف هدفًا أو أكثر — سيساعدك Atlas على تحقيقها',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: goalController,
                  decoration: const InputDecoration(hintText: 'مثال: النجاح في الامتحان'),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      onAdd(v.trim());
                      goalController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  if (goalController.text.trim().isNotEmpty) {
                    onAdd(goalController.text.trim());
                    goalController.clear();
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goals
                .map((g) => Chip(
                      label: Text(g),
                      onDeleted: () => onRemove(g),
                      backgroundColor: AppColors.surfaceVariant,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SleepStep extends StatelessWidget {
  final TimeOfDay wakeTime;
  final TimeOfDay sleepTime;
  final ValueChanged<TimeOfDay> onWakeChanged;
  final ValueChanged<TimeOfDay> onSleepChanged;

  const _SleepStep({
    required this.wakeTime,
    required this.sleepTime,
    required this.onWakeChanged,
    required this.onSleepChanged,
  });

  Future<void> _pick(BuildContext context, TimeOfDay initial, ValueChanged<TimeOfDay> onChanged) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('روتين نومك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Atlas لن يجدول أي شيء فوق وقت نومك أبدًا',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _TimeTile(
            label: 'وقت الاستيقاظ',
            time: wakeTime,
            icon: Icons.wb_sunny_outlined,
            onTap: () => _pick(context, wakeTime, onWakeChanged),
          ),
          const SizedBox(height: 12),
          _TimeTile(
            label: 'وقت النوم',
            time: sleepTime,
            icon: Icons.nightlight_round,
            onTap: () => _pick(context, sleepTime, onSleepChanged),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeTile({required this.label, required this.time, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: Text(time.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
