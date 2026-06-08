import 'package:flutter/material.dart';

/// 设置页骨架。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsSection(
            title: '基础',
            children: [
              _PlaceholderTile(
                icon: Icons.timer_outlined,
                title: '计时偏好',
                subtitle: '后续可放入默认显示、提醒、打点等选项',
                color: cs.primary,
              ),
              _PlaceholderTile(
                icon: Icons.palette_outlined,
                title: '外观',
                subtitle: '后续可放入主题、字体和窗口显示选项',
                color: cs.secondary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: '数据',
            children: [
              _PlaceholderTile(
                icon: Icons.storage_outlined,
                title: '本地数据',
                subtitle: '后续可放入导入、导出和备份相关功能',
                color: cs.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.56),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _PlaceholderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: color.withValues(alpha: 0.82)),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.48)),
      ),
      enabled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
