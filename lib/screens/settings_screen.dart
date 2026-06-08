import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/stopwatch_font_preset.dart';

/// 设置页骨架。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(stopwatchSettingsProvider);
    final selectedFont =
        settingsAsync.value?.stopwatchFontPreset ??
        StopwatchFontPreset.defaultPreset;
    final settingsNotifier = ref.read(stopwatchSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsSection(
            title: '基础',
            children: [
              _FontPresetGroup(
                selectedFont: selectedFont,
                isLoading: settingsAsync.isLoading,
                onChanged: settingsNotifier.setStopwatchFontPreset,
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

class _FontPresetGroup extends StatelessWidget {
  final StopwatchFontPreset selectedFont;
  final bool isLoading;
  final ValueChanged<StopwatchFontPreset> onChanged;

  const _FontPresetGroup({
    required this.selectedFont,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final presets = StopwatchFontPreset.values;

    return RadioGroup<StopwatchFontPreset>(
      groupValue: selectedFont,
      onChanged: (value) {
        if (!isLoading && value != null) onChanged(value);
      },
      child: Column(
        children: [
          for (var i = 0; i < presets.length; i++) ...[
            _FontPresetTile(
              preset: presets[i],
              selectedFont: selectedFont,
              isLoading: isLoading,
              onChanged: onChanged,
            ),
            if (i < presets.length - 1) const _SettingsDivider(),
          ],
        ],
      ),
    );
  }
}

class _FontPresetTile extends StatelessWidget {
  final StopwatchFontPreset preset;
  final StopwatchFontPreset selectedFont;
  final bool isLoading;
  final ValueChanged<StopwatchFontPreset> onChanged;

  const _FontPresetTile({
    required this.preset,
    required this.selectedFont,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = preset == selectedFont;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : () => onChanged(preset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              Icon(
                Icons.format_size_rounded,
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.88)
                    : cs.onSurface.withValues(alpha: 0.36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preset.description,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.48),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '12:34:56',
                style: preset.textStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontSize: 18,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Radio<StopwatchFontPreset>(value: preset, enabled: !isLoading),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: cs.onSurface.withValues(alpha: 0.06),
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
