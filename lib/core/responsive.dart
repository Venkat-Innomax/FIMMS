import 'package:flutter/widgets.dart';

/// Responsive breakpoint helper. Use a single codebase across phone,
/// tablet, and desktop with a centralised definition of screen sizes.
///
/// Breakpoints:
///   Mobile  : width < 600
///   Tablet  : 600 <= width < 1024
///   Desktop : width >= 1024
class Responsive {
  Responsive._();

  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileMaxWidth && w < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMaxWidth;

  /// Pick a value based on the current breakpoint. `tablet` falls back to
  /// `mobile` when omitted; `desktop` falls back to `tablet` when omitted.
  static T when<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tabletMaxWidth) return desktop ?? tablet ?? mobile;
    if (width >= mobileMaxWidth) return tablet ?? mobile;
    return mobile;
  }
}
