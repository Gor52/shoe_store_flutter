import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Вспомогательный метод для создания красивых карточек меню
  Widget _buildDashboardCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // ИСПРАВЛЕНО: context.push заменен на context.go для обновления адресной строки
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title, 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle, 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    final role = context.watch<AuthNotifier>().userRole;
    final isAdmin = role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Панель администратора' : 'Панель менеджера', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 0.85,
          children: [
            _buildDashboardCard(
              context,
              title: 'Заказы',
              subtitle: 'Обработка заказов',
              icon: Icons.receipt_long,
              color: Colors.indigo,
              route: '/admin/orders',
            ),
            _buildDashboardCard(
              context,
              title: 'Обувь',
              subtitle: 'Управление каталогом',
              icon: Icons.shopping_bag,
              color: Colors.purple,
              route: '/admin/shoes',
            ),
            _buildDashboardCard(
              context,
              title: 'Склад',
              subtitle: 'Размеры и остатки',
              icon: Icons.inventory,
              color: Colors.orange,
              route: '/admin/stocks',
            ),

            if (isAdmin)
              _buildDashboardCard(
                context,
                title: 'Пользователи',
                subtitle: 'Управление аккаунтами',
                icon: Icons.people,
                color: Colors.teal,
                route: '/admin/users',
              ),
            if (isAdmin)
              _buildDashboardCard(
                context,
                title: 'Бренды',
                subtitle: 'Управление брендами',
                icon: Icons.branding_watermark,
                color: Colors.blue,
                route: '/admin/brands',
              ),
            if (isAdmin)
              _buildDashboardCard(
                context,
                title: 'Категории',
                subtitle: 'Структура каталога',
                icon: Icons.category,
                color: Colors.green,
                route: '/admin/categories',
              ),

            if (!isAdmin)
              _buildDashboardCard(
                context,
                title: 'Отчет смены',
                subtitle: 'Личная сводка',
                icon: Icons.analytics,
                color: Colors.orange,
                route: '/manager/report',
              ),
          ],
        ),
      ),
    );
  }
}