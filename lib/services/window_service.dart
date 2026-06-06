import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../theme/app_colors.dart';

/// 窗口管理服务 —— 控制 正常模式 ↔ 悬浮模式 切换
class WindowService {
  static const _normalSize = Size(420, 720);
  static const _floatingSize = Size(208, 174);
  static const _floatingMaxSize = Size(302, 252);
  static const _normalMinSize = Size(280, 400);
  static const _unboundedMaxSize = Size(10000, 10000);
  static const _floatingAspectRatio = 208 / 174;

  static bool _isFloating = false;

  static bool get isFloating => _isFloating;

  /// 初始化 window_manager（在 main 中调用）
  static Future<void> init() async {
    if (!_isDesktop) return;
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);

    // 默认窗口选项
    final options = WindowOptions(
      size: _normalSize,
      center: true,
      minimumSize: _normalMinSize,
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: AppColors.darkSurface,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  /// 切换到悬浮模式：紧凑、无边框、置顶、右上角
  static Future<void> enterFloatingMode() async {
    if (!_isDesktop) return;

    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setAspectRatio(0);
    await windowManager.setMaximumSize(_unboundedMaxSize);
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    }
    await windowManager.setMinimumSize(_floatingSize);
    await windowManager.setSize(_floatingSize);
    await windowManager.setMaximumSize(_floatingMaxSize);
    await windowManager.setResizable(true);
    await windowManager.setAspectRatio(_floatingAspectRatio);
    await windowManager.setAlwaysOnTop(true);
    // 放到右上角
    final screenSize = await _getScreenSize();
    await windowManager.setPosition(
      Offset(screenSize.width - _floatingSize.width - 20, 60),
    );
    await windowManager.focus();
    _isFloating = true;
  }

  /// 退出悬浮模式，恢复正常窗口
  static Future<void> exitFloatingMode() async {
    if (!_isDesktop) return;
    _isFloating = false;

    await windowManager.setAspectRatio(0);
    await windowManager.setMaximumSize(_unboundedMaxSize);
    await windowManager.setMinimumSize(_normalMinSize);
    await windowManager.setResizable(true);
    await windowManager.setSize(_normalSize);
    await windowManager.center();
    await windowManager.setAlwaysOnTop(false);
    await windowManager.focus();
  }

  /// 请求关闭窗口，交给 AppRoot.onWindowClose 执行保存和退出流程。
  static Future<void> closeWindow() async {
    if (!_isDesktop) return;
    await windowManager.close();
  }

  /// 最小化窗口。
  static Future<void> minimizeWindow() async {
    if (!_isDesktop) return;
    await windowManager.minimize();
  }

  /// 最大化或还原窗口。
  static Future<void> toggleMaximizeWindow() async {
    if (!_isDesktop) return;
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  /// 获取当前屏幕尺寸（逻辑像素）
  static Future<Size> _getScreenSize() async {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final display = view.display;
      return display.size / display.devicePixelRatio;
    } catch (_) {
      return const Size(1920, 1080);
    }
  }
}
