import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../repositories/shoe_repository.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await context.read<ShoeRepository>().getAllOrders();
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showOrderDetails(Order order) async {
    String currentStatus = order.status;
    final statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (!statuses.contains(currentStatus)) statuses.add(currentStatus);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // StatefulBuilder нужен, чтобы менять состояние внутри диалога
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Детали заказа', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ID заказа: ${order.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Дата: ${order.created.toLocal().toString().split('.')[0]}'),
                  const Divider(height: 24),
                  
                  const Text('Данные покупателя:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Имя: ${order.userName?.isNotEmpty == true ? order.userName : "Не указано"}'),
                  Text('Email: ${order.userEmail ?? "Не указан"}'),
                  const Divider(height: 24),
                  
                  Text('Сумма: ${order.totalAmount} руб.', style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Статус заказа', border: OutlineInputBorder()),
                    value: currentStatus,
                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => currentStatus = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
              FilledButton(
                onPressed: () async {
                  try {
                    await context.read<ShoeRepository>().updateOrderStatus(order.id, currentStatus);
                    if (context.mounted) Navigator.pop(context);
                    _loadOrders(); // Перезагружаем список заказов
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Все заказы (Админ)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('Заказов пока нет'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final customerName = order.userName?.isNotEmpty == true ? order.userName! : (order.userEmail ?? 'Аноним');
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.receipt_long, color: Colors.white)),
                        title: Text('От: $customerName', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Статус: ${order.status.toUpperCase()}'),
                            Text('Сумма: ${order.totalAmount} руб.', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showOrderDetails(order), // Открытие деталей
                      ),
                    );
                  },
                ),
    );
  }
}