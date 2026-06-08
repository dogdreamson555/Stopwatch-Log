import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';

import '../providers/settings_provider.dart';
import '../theme/stopwatch_font_preset.dart';

/// 设置页骨架。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(stopwatchSettingsProvider);
    final settings = settingsAsync.value ?? const StopwatchSettings();
    final selectedFont = settings.effectiveFontPreset;
    final settingsNotifier = ref.read(stopwatchSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsSection(
            title: '秒表显示',
            children: [
              _FontChoiceGroup(
                settings: settings,
                selectedFont: selectedFont,
                isLoading: settingsAsync.isLoading,
                onChanged: settingsNotifier.setStopwatchFontPreset,
                onImport: () => _pickAndImportFont(context, ref),
              ),
              const _SettingsDivider(),
              _SliderTile(
                icon: Icons.numbers_rounded,
                title: '数字大小',
                value: settings.digitScale,
                min: 0.75,
                max: 1.35,
                divisions: 24,
                valueLabel: _formatPercent(settings.digitScale),
                onChanged: settingsAsync.isLoading
                    ? null
                    : (value) => settingsNotifier.setDigitScale(value),
              ),
              const _SettingsDivider(),
              _SliderTile(
                icon: Icons.more_vert_rounded,
                title: '冒号大小',
                value: settings.colonScale,
                min: 0.7,
                max: 1.45,
                divisions: 30,
                valueLabel: _formatPercent(settings.colonScale),
                onChanged: settingsAsync.isLoading
                    ? null
                    : (value) => settingsNotifier.setColonScale(value),
              ),
              const _SettingsDivider(),
              _SliderTile(
                icon: Icons.swap_horiz_rounded,
                title: '数字与冒号间距',
                value: settings.separatorSpacing,
                min: 0,
                max: 14,
                divisions: 28,
                valueLabel:
                    '${settings.separatorSpacing.toStringAsFixed(1)} px',
                onChanged: settingsAsync.isLoading
                    ? null
                    : (value) => settingsNotifier.setSeparatorSpacing(value),
              ),
              const _SettingsDivider(),
              _ResetDisplayTile(
                onReset: settingsAsync.isLoading
                    ? null
                    : settingsNotifier.resetDisplayTuning,
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

  Future<void> _pickAndImportFont(BuildContext context, WidgetRef ref) async {
    const fontTypeGroup = XTypeGroup(
      label: '字体文件',
      extensions: ['ttf', 'otf', 'ttc'],
    );

    final messenger = ScaffoldMessenger.of(context);
    final selectedFile = await openFile(
      acceptedTypeGroups: const [fontTypeGroup],
      confirmButtonText: '导入',
    );
    if (selectedFile == null) return;

    try {
      await ref
          .read(stopwatchSettingsProvider.notifier)
          .importCustomFont(selectedFile.path);
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('字体已导入')));
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_formatImportError(error))),
      );
    }
  }

  String _formatImportError(Object error) {
    final message = error.toString();
    if (message.contains('字体文件不存在')) return '字体文件不存在';
    if (message.contains('仅支持')) return '仅支持 .ttf、.otf、.ttc 字体文件';
    if (message.contains('请输入')) return '请输入字体文件路径';
    return '导入失败，请检查字体文件';
  }

  String _formatPercent(double value) {
    return '${(value * 100).round()}%';
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
    const presets = StopwatchFontPreset.builtInPresets;

    return Column(
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
    );
  }
}

class _FontChoiceGroup extends StatelessWidget {
  final StopwatchSettings settings;
  final StopwatchFontPreset selectedFont;
  final bool isLoading;
  final ValueChanged<StopwatchFontPreset> onChanged;
  final VoidCallback onImport;

  const _FontChoiceGroup({
    required this.settings,
    required this.selectedFont,
    required this.isLoading,
    required this.onChanged,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<StopwatchFontPreset>(
      groupValue: selectedFont,
      onChanged: (value) {
        if (!isLoading && value != null) onChanged(value);
      },
      child: Column(
        children: [
          _FontPresetGroup(
            selectedFont: selectedFont,
            isLoading: isLoading,
            onChanged: onChanged,
          ),
          const _SettingsDivider(),
          _CustomFontTile(
            settings: settings,
            isLoading: isLoading,
            onSelect: () => onChanged(StopwatchFontPreset.custom),
            onImport: onImport,
          ),
        ],
      ),
    );
  }
}

class _CustomFontTile extends StatelessWidget {
  final StopwatchSettings settings;
  final bool isLoading;
  final VoidCallback onSelect;
  final VoidCallback onImport;

  const _CustomFontTile({
    required this.settings,
    required this.isLoading,
    required this.onSelect,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasCustomFont = settings.hasCustomFont;
    final isSelected =
        settings.effectiveFontPreset == StopwatchFontPreset.custom;
    final title = hasCustomFont
        ? settings.customFontLabel ?? StopwatchFontPreset.custom.label
        : StopwatchFontPreset.custom.label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading || !hasCustomFont ? null : onSelect,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              Icon(
                Icons.upload_file_rounded,
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
                      title,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasCustomFont ? '已导入本地字体' : '导入 .ttf / .otf / .ttc',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.48),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasCustomFont) ...[
                Text(
                  '12:34:56',
                  style: StopwatchFontPreset.custom.textStyle(
                    customFontFamily: settings.customFontFamily,
                    color: cs.onSurface.withValues(alpha: 0.72),
                    fontSize: 18,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Radio<StopwatchFontPreset>(
                  value: StopwatchFontPreset.custom,
                  enabled: !isLoading && hasCustomFont,
                ),
                const SizedBox(width: 2),
              ],
              Tooltip(
                message: '导入字体',
                child: IconButton(
                  onPressed: isLoading ? null : onImport,
                  icon: const Icon(Icons.file_upload_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double>? onChanged;

  const _SliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurface.withValues(alpha: 0.44)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      valueLabel,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.52),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: value.clamp(min, max).toDouble(),
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: valueLabel,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetDisplayTile extends StatelessWidget {
  final VoidCallback? onReset;

  const _ResetDisplayTile({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.restart_alt_rounded),
      title: const Text('恢复默认显示参数'),
      trailing: IconButton(
        tooltip: '恢复默认',
        onPressed: onReset,
        icon: const Icon(Icons.refresh_rounded),
      ),
      onTap: onReset,
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
