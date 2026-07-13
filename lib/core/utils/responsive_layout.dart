import 'package:flutter/material.dart';

class ResponsiveLayout {
  // Breakpoints
  static const double mobileLimit = 600;
  static const double tabletLimit = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileLimit;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileLimit &&
      MediaQuery.of(context).size.width < tabletLimit;

  static bool isDesktopOrTV(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletLimit;

  static int getCrossAxisCount(BuildContext context, {
    int mobile = 1,
    int tablet = 3,
    int desktop = 5,
  }) {
    if (isDesktopOrTV(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
