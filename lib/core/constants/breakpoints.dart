import 'package:flutter/widgets.dart';

class Breakpoints {
  Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < tablet;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;
}
