import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
import '../providers/session_archive_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';
import '../services/local_data_backup_service.dart';
import '../theme/stopwatch_font_preset.dart';

/// 设置页骨架。
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDataOperationRunning = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settingsAsync = ref.watch(stopwatchSettingsProvider);
    final settings = settingsAsync.value ?? const StopwatchSettings();
    final selectedFont = settings.effectiveFontPreset;
    final settingsNotifier = ref.read(stopwatchSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: _DraggableAppBarTitle(title: l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsSection(
            title: l10n.general,
            children: [
              _LanguageTile(
                language: settings.appLanguage,
                isLoading: settingsAsync.isLoading,
                onChanged: settingsNotifier.setAppLanguage,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: l10n.stopwatchDisplay,
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
                title: l10n.digitSize,
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
                title: l10n.colonSize,
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
                title: l10n.digitColonSpacing,
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
            title: l10n.data,
            children: [
              _DataActionTile(
                icon: Icons.file_upload_outlined,
                title: l10n.exportData,
                subtitle: l10n.exportDataDescription,
                isLoading: _isDataOperationRunning,
                onTap: () => _exportLocalData(context),
              ),
              const _SettingsDivider(),
              _DataActionTile(
                icon: Icons.file_download_outlined,
                title: l10n.importData,
                subtitle: l10n.importDataDescription,
                isLoading: _isDataOperationRunning,
                onTap: () => _importLocalData(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndImportFont(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final fontTypeGroup = XTypeGroup(
      label: l10n.fontFile,
      extensions: ['ttf', 'otf', 'ttc'],
    );

    final messenger = ScaffoldMessenger.of(context);
    final selectedFile = await openFile(
      acceptedTypeGroups: [fontTypeGroup],
      confirmButtonText: l10n.importAction,
    );
    if (selectedFile == null) return;

    try {
      await ref
          .read(stopwatchSettingsProvider.notifier)
          .importCustomFont(selectedFile.path);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.fontImported)));
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_formatImportError(error, l10n))),
      );
    }
  }

  String _formatImportError(Object error, AppLocalizations l10n) {
    final message = error.toString();
    if (message.contains('字体文件不存在')) return l10n.fontFileMissing;
    if (message.contains('仅支持')) return l10n.unsupportedFontFile;
    if (message.contains('请输入')) return l10n.fontPathRequired;
    return l10n.fontImportFailed;
  }

  Future<void> _exportLocalData(BuildContext context) async {
    final l10n = context.l10n;
    final fileName =
        'stopwatch-log-backup-${_fileTimestamp(DateTime.now())}.json';
    final backupTypeGroup = XTypeGroup(
      label: l10n.backupFile,
      extensions: const ['json'],
    );
    final location = await getSaveLocation(
      acceptedTypeGroups: [backupTypeGroup],
      suggestedName: fileName,
      confirmButtonText: l10n.exportAction,
    );
    if (location == null || !mounted) return;

    setState(() => _isDataOperationRunning = true);
    try {
      await ref.read(timerProvider.notifier).persistNow();
      final service = LocalDataBackupService(ref.read(databaseProvider));
      final json = await service.exportToJson();
      final backupFile = XFile.fromData(
        Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        name: fileName,
      );
      await backupFile.saveTo(location.path);
      if (!context.mounted) return;
      _showMessage(context, l10n.dataExported);
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, l10n.dataExportFailed);
    } finally {
      if (mounted) setState(() => _isDataOperationRunning = false);
    }
  }

  Future<void> _importLocalData(BuildContext context) async {
    final l10n = context.l10n;
    final canImport = await ref
        .read(timerProvider.notifier)
        .prepareForDataImport();
    if (!context.mounted) return;

    if (!canImport) {
      _showMessage(context, l10n.stopTimerBeforeImport);
      return;
    }

    final backupTypeGroup = XTypeGroup(
      label: l10n.backupFile,
      extensions: const ['json'],
    );
    final selectedFile = await openFile(
      acceptedTypeGroups: [backupTypeGroup],
      confirmButtonText: l10n.importAction,
    );
    if (selectedFile == null || !context.mounted) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.confirmDataImport),
            content: Text(l10n.importDataWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.replaceData),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _isDataOperationRunning = true);
    try {
      final source = await selectedFile.readAsString();
      final service = LocalDataBackupService(ref.read(databaseProvider));
      final backup = await service.importFromJson(source);

      ref.invalidate(sessionArchiveProvider);
      ref.invalidate(stopwatchSettingsProvider);
      ref.invalidate(timerProvider);

      if (!context.mounted) return;
      _showMessage(
        context,
        l10n.dataImported(backup.sessions.length, backup.points.length),
      );
    } on FormatException {
      if (!context.mounted) return;
      _showMessage(context, l10n.invalidBackupFile);
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, l10n.dataImportFailed);
    } finally {
      if (mounted) setState(() => _isDataOperationRunning = false);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatPercent(double value) {
    return '${(value * 100).round()}%';
  }
}

class _DraggableAppBarTitle extends StatelessWidget {
  final String title;

  const _DraggableAppBarTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => windowManager.startDragging(),
      child: SizedBox(
        width: double.infinity,
        height: kToolbarHeight,
        child: Align(alignment: Alignment.centerLeft, child: Text(title)),
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

class _LanguageTile extends StatelessWidget {
  final AppLanguage language;
  final bool isLoading;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguageTile({
    required this.language,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Builder(
      builder: (tileContext) => ListTile(
        enabled: !isLoading,
        onTap: isLoading ? null : () => _showLanguageMenu(tileContext),
        leading: Icon(
          Icons.translate_rounded,
          color: cs.primary.withValues(alpha: 0.82),
        ),
        title: Text(context.l10n.language),
        subtitle: Text(
          language.nativeName,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.48)),
        ),
        trailing: const Icon(Icons.arrow_drop_down_rounded),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Future<void> _showLanguageMenu(BuildContext context) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final tile = context.findRenderObject() as RenderBox;
    final tileTopLeft = tile.localToGlobal(Offset.zero, ancestor: overlay);
    const trailingPadding = 16.0;
    const trailingWidth = 24.0;
    final anchorRight = tileTopLeft.dx + tile.size.width - trailingPadding;
    final anchorLeft = anchorRight - trailingWidth;
    final anchorTop = tileTopLeft.dy + tile.size.height;

    final selected = await showMenu<AppLanguage>(
      context: context,
      position: RelativeRect.fromLTRB(
        anchorLeft,
        anchorTop,
        overlay.size.width - anchorRight,
        overlay.size.height - anchorTop,
      ),
      items: [
        for (final option in AppLanguage.values)
          CheckedPopupMenuItem(
            value: option,
            checked: option == language,
            child: Text(option.nativeName),
          ),
      ],
    );
    if (!context.mounted || selected == null) return;
    onChanged(selected);
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
    final l10n = context.l10n;
    final hasCustomFont = settings.hasCustomFont;
    final isSelected =
        settings.effectiveFontPreset == StopwatchFontPreset.custom;
    final title = hasCustomFont
        ? settings.customFontLabel ?? l10n.customFont
        : l10n.customFont;

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
                      hasCustomFont
                          ? l10n.importedLocalFont
                          : l10n.importFontTypes,
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
                message: l10n.importFont,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
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
                const SizedBox(height: 2),
                SizedBox(
                  height: 32,
                  child: Slider(
                    value: value.clamp(min, max).toDouble(),
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: valueLabel,
                    onChanged: onChanged,
                  ),
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
      title: Text(context.l10n.resetDisplay),
      trailing: IconButton(
        tooltip: context.l10n.resetDefault,
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
    final l10n = context.l10n;
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
                      _fontPresetLabel(preset, l10n),
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _fontPresetDescription(preset, l10n),
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

class _DataActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _DataActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: cs.tertiary.withValues(alpha: 0.82)),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.48)),
      ),
      trailing: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right_rounded),
      enabled: !isLoading,
      onTap: isLoading ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

String _fontPresetLabel(StopwatchFontPreset preset, AppLocalizations l10n) {
  return switch (preset) {
    StopwatchFontPreset.custom => l10n.customFont,
    _ => preset.label,
  };
}

String _fontPresetDescription(
  StopwatchFontPreset preset,
  AppLocalizations l10n,
) {
  return switch (preset) {
    StopwatchFontPreset.segoeDisplay => l10n.segoeDescription,
    StopwatchFontPreset.cascadiaMono => l10n.cascadiaDescription,
    StopwatchFontPreset.consolas => l10n.consolasDescription,
    StopwatchFontPreset.bahnschrift => l10n.bahnschriftDescription,
    StopwatchFontPreset.custom => l10n.customFontDescription,
  };
}

String _fileTimestamp(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}'
      '${twoDigits(value.month)}'
      '${twoDigits(value.day)}-'
      '${twoDigits(value.hour)}'
      '${twoDigits(value.minute)}'
      '${twoDigits(value.second)}';
}
