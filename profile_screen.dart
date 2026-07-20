import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final milestones = AppConstants.rankTitles.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.person, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Level ${user.level} · ${user.rankTitle}',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('التقدم نحو المستوى القادم', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (user.xp / user.xpToNextLevel()).clamp(0, 1),
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${user.xp} / ${user.xpToNextLevel()} XP',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('أهدافك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (user.goals.isEmpty)
            const Text('لم تضف أهدافًا بعد', style: TextStyle(color: AppColors.textSecondary))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.goals
                  .map((g) => Chip(label: Text(g), backgroundColor: AppColors.surfaceVariant))
                  .toList(),
            ),
          const SizedBox(height: 20),
          const Text('الرتب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...milestones.map((level) {
            final unlocked = user.level >= level;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                unlocked ? Icons.emoji_events : Icons.lock_outline,
                color: unlocked ? AppColors.warning : AppColors.textSecondary,
              ),
              title: Text('Level $level: ${AppConstants.rankTitles[level]}'),
              trailing: unlocked ? const Icon(Icons.check, color: AppColors.accent) : null,
            );
          }),
        ],
      ),
    );
  }
}
