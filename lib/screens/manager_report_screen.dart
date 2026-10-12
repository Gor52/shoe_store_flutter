import 'package:flutter/material.dart';

class ManagerReportScreen extends StatelessWidget {
  const ManagerReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сводка для менеджера')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Рабочая смена', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Этот раздел доступен только менеджерам.\nАдминистраторы сюда зайти не могут.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}