/// Centralized spacing, duration, and breakpoint design tokens for FIMMS.

class Spacing {
  Spacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class FimmsDurations {
  FimmsDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 800;
  static const double desktop = 1024;
  static const double wide = 1280;
}
