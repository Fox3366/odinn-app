import 'package:flutter/material.dart';

/// Uygulamanın tüm renk sabitleri tek yerden yönetilir.
/// Herhangi bir widget doğrudan bu sınıfı import eder.
abstract class AppColors {
  static const Color bg      = Color(0xFF080808);
  static const Color surface = Color(0xFF0F0F0F);
  static const Color red     = Color(0xFFD32F2F);
  static const Color redL    = Color(0xFFFF5252);
  static const Color green   = Color(0xFF00C853);
  static const Color white   = Color(0xFFEEEEEE);
  static const Color grey    = Color(0xFF888888);
  static const Color greyD   = Color(0xFF222222);
  static const Color amber   = Color(0xFFFFB300);
  static const Color cyan    = Color(0xFF00BCD4);
  static const Color grid    = Color(0xFF1A1A1A);
}