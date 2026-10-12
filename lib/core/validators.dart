class AppValidators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите email';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Неверный формат email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите телефон';
    final regex = RegExp(r'^\+?[0-9]{10,14}$');
    if (!regex.hasMatch(value.trim())) return 'Формат: +79991234567';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < 8) return 'Минимум 8 символов';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите цену';
    final price = double.tryParse(value);
    if (price == null) return 'Только числа';
    if (price <= 0) return 'Цена должна быть больше 0';
    if (price > 1000000) return 'Слишком большая цена';
    return null;
  }
}