import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Тесты виджетов (Widget Tests)', () {

    testWidgets('1. Проверка отображения кнопки и текста в простой форме', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {},
                child: const Text('Сохранить'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Сохранить'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('2. Проверка отображения индикатора загрузки (CircularProgressIndicator)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('3. Проверка текстового поля (TextFormField) и ввода данных', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Название'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Кроссовки Nike');
      expect(controller.text, 'Кроссовки Nike');
    });

    testWidgets('4. Проверка работы переключателя (Checkbox)', (WidgetTester tester) async {
      bool isChecked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Checkbox(
                value: isChecked,
                onChanged: (val) {
                  setState(() {
                    isChecked = val ?? false;
                  });
                },
              ),
            ),
          ),
        ),
      );

      Checkbox checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, false);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('5. Проверка отображения диалогового окна (AlertDialog)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('Внимание'),
                      content: Text('Точно удалить элемент?'),
                    ),
                  );
                },
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Внимание'), findsNothing);

      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle(); 

      expect(find.text('Внимание'), findsOneWidget);
      expect(find.text('Точно удалить элемент?'), findsOneWidget);
    });

  });
}