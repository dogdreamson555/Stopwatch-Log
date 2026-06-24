import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/ui_provider.dart';
import 'screens/timer_screen.dart';
import 'services/window_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';
import 'widgets/floating_timer.dart';

// ── 主题颜色定义 ──

const _seedColor = Color(0xFF4FC3F7);

final _lightColorScheme = ColorScheme.fromSeed(
  seedColor: _seedColor,
  brightness: Brightness.light,
  primary: const Color(0xFF0277BD),
  secondary: const Color(0xFF43A047),
  tertiary: const Color(0xFFEF6C00),
  error: const Color(0xFFD32F2F),
  surface: const Color(0xFFF8F9FA),
);

final _darkColorScheme = ColorScheme.fromSeed(
  seedColor: _seedColor,
  brightness: Brightness.dark,
  primary: const Color(0xFF5AC8F5),
  secondary: const Color(0xFF7ED68D),
  tertiary: const Color(0xFFFF9F45),
  error: const Color(0xFFFF5A5F),
  surface: AppColors.darkSurface,
  surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
  onSurface: const Color(0xFFF3F3F3),
);

ThemeData _buildTheme(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surfaceContainerHighest,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.onSurface.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(14),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.primary,
      contentTextStyle: TextStyle(color: colorScheme.onPrimary),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowService.init();

  // 允许状态栏跟随系统主题透明（Windows 上不影响）
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const ProviderScope(child: StopwatchLogApp()));
}

class StopwatchLogApp extends ConsumerWidget {
  const StopwatchLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: _buildTheme(_lightColorScheme),
      darkTheme: _buildTheme(_darkColorScheme),
      themeMode: ThemeMode.system,
      home: const AppRoot(),
    );
  }
}

/// 根组件：根据悬浮模式切换显示 全屏 / 悬浮窗
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot>
    with WidgetsBindingObserver, WindowListener {
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ref.read(timerProvider.notifier).persistNow();
    }
  }

  @override
  Future<void> onWindowClose() async {
    if (_isClosing) return;
    _isClosing = true;

    try {
      await ref.read(timerProvider.notifier).persistNow();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'stopwatch_log',
          context: ErrorDescription('saving timer draft before window close'),
        ),
      );
    } finally {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFloating = ref.watch(isFloatingModeProvider);

    return isFloating ? const FloatingTimer() : const TimerScreen();
  }
}
