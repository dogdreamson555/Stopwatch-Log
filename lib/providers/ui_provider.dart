import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 悬浮模式状态管理
class FloatingModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() => state = true;
  void exit() => state = false;
}

/// 悬浮模式开关 Provider
final isFloatingModeProvider = NotifierProvider<FloatingModeNotifier, bool>(
  FloatingModeNotifier.new,
);
