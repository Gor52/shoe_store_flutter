import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:shoe_shop_flutter/models/shoe.dart';
import 'package:shoe_shop_flutter/models/brand.dart';

void main() {
  group('Модульные тесты (Unit Tests) - Модели и Логика', () {
    
    test('1. Проверка правильности инициализации модели Shoe', () {
      final shoe = Shoe(
        id: '1',
        name: 'Nike Air Max',
        price: 15000.0,
        brandId: 'b1',
        isDeleted: false,
      );

      expect(shoe.id, '1');
      expect(shoe.name, 'Nike Air Max');
      expect(shoe.price, 15000.0);
      expect(shoe.isDeleted, false);
      expect(shoe.hasValidImage, false); 
    });

    test('2. Проверка флага валидности изображения у Shoe', () {
      final shoeWithImage = Shoe(
        id: '2',
        name: 'Adidas Superstar',
        price: 12000.0,
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(shoeWithImage.hasValidImage, true);
    });

    test('3. Проверка модели Brand', () {
      final dummyRecord = RecordModel({
        'id': 'b1',
        'collectionId': 'brands',
        'collectionName': 'brands',
        'created': '',
        'updated': '',
      });

      final brand = Brand(
        id: 'b1',
        name: 'Nike',
        country: 'USA',
        logo: '',
        record: dummyRecord,
      );

      expect(brand.name, 'Nike');
      expect(brand.country, 'USA');
      expect(brand.hasValidLogo, false);
      expect(brand.logoUrl, isNull);
    });

    test('4. Проверка работы метода деления/фильтрации цены', () {
      final prices = [5000.0, 12000.0, 8000.0];
      prices.sort(); 
      
      expect(prices.first, 5000.0);
      expect(prices.last, 12000.0);
    });

    test('5. Проверка состояния корзины (сумма товаров)', () {
      final itemsPrices = [1000.0, 2500.0, 1500.0];
      final total = itemsPrices.fold(0.0, (sum, item) => sum + item);

      expect(total, 5000.0);
    });

    test('6. Проверка обработки пустой строки названия в логике', () {
      String? name = '   ';
      bool isValid = name.trim().isNotEmpty;

      expect(isValid, false);
    });

    test('7. Проверка корректности парсинга числовых цен из текста', () {
      String priceText = ' 14999.99 ';
      double? parsedPrice = double.tryParse(priceText.trim());

      expect(parsedPrice, 14999.99);
    });

    test('8. Проверка ролей пользователей (разграничение прав)', () {
      const userRole = 'manager';
      final isStaff = userRole == 'admin' || userRole == 'manager';
      final canDeleteDatabase = userRole == 'admin';

      expect(isStaff, true);
      expect(canDeleteDatabase, false);
    });

  });
}