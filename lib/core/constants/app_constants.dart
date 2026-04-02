import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Ramiz Mehmood';
  static const String appRole = 'Computer Scientist & AI Researcher';
  static const String appEmail = 'ramizmehmood8513@gmail.com';
  static const String appInitials = 'RM';
  static const String appCopyright = '© 2026 Ramiz. All rights reserved.';

  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space18 = 18.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;

  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusFull = 999.0;

  static const double iconXS = 12.0;
  static const double iconSM = 16.0;
  static const double iconMD = 20.0;
  static const double iconLG = 24.0;

  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 905.0;
  static const double breakpointDesktop = 1240.0;

  static const double maxContentWidth = 1440.0;
  static const double sidebarCollapsed = 72.0;
  static const double sidebarExpanded = 360.0;
  static const double topBarHeight = 64.0;
  static const double bottomBarHeight = 56.0;

  static const Duration durationInstant = Duration(milliseconds: 100);
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  static const Curve curveStandard = Curves.easeInOutCubicEmphasized;
  static const Curve curveDecelerate = Curves.easeOut;
  static const Curve curveAccelerate = Curves.easeIn;

  static bool isMobile(double width) => width < breakpointMobile;
  static bool isTablet(double width) =>
      width >= breakpointMobile && width < breakpointTablet;
  static bool isDesktop(double width) => width >= breakpointTablet;
}
