/// Конфигурация Xwend.
/// URL и ключ — ваши реальные из Supabase.
class AppConfig {
  static const String supabaseUrl =
      'https://mdggylqccbgzciirnizs.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_z3kEFV2D8pXZzKxP4QMUsw_thDkdBF7';
  static const String donateUrl =
      'https://www.donationalerts.com/r/xwend';

  static const String mediaBucket = 'xwend-media';
  static const String adminUsername = 'xwend';

  /// Пакеты пополнения звёзд (можно расширить).
  static const List<Map<String, dynamic>> donatePackages = [
    {'stars': 100, 'price': '99 ₽', 'label': 'Старт'},
    {'stars': 500, 'price': '449 ₽', 'label': 'Плюс'},
    {'stars': 1000, 'price': '849 ₽', 'label': 'Про'},
    {'stars': 5000, 'price': '3990 ₽', 'label': 'VIP'},
  ];
}