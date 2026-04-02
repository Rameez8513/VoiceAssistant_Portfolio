import 'package:flutter/material.dart';

class ThemeProvider extends InheritedWidget {
  final ThemeMode themeMode;
  final VoidCallback toggleTheme;

  const ThemeProvider({
    super.key,
    required this.themeMode,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  static ThemeProvider of(BuildContext context) {
    final provider = maybeOf(context);
    assert(provider != null, 'ThemeProvider not found in context');
    return provider!;
  }

  bool get isDark => themeMode == ThemeMode.dark;
  bool get isLight => themeMode == ThemeMode.light;

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return oldWidget.themeMode != themeMode;
  }
}
