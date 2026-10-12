import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/cart_notifier.dart';
import '../repositories/shoe_repository.dart';
import '../state/auth_notifier.dart';
import '../core/api_client.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isOrdering = false;

  Future<void> _checkout() async {
    final cart = context.read<CartNotifier>();
    final auth = context.read<AuthNotifier>();
    
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Авторизуйтесь для оформления заказа')));
      return;
    }

    if (cart.items.isEmpty) return;

    setState(() => _isOrdering = true);
    try {
      final itemsPayload = cart.items.map((item) => {
        'stockId': item.stock.id,
        'quantity': item.quantity,
        'price': item.shoe.price,
      }).toList();

      await context.read<ShoeRepository>().createCompleteOrder(
        userId: pb.authStore.record!.id,
        cartItems: itemsPayload,
      );
     
      cart.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заказ успешно оформлен одним чеком!'), 
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка оформления: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: cart.items.isEmpty
          ? const Center(child: Text('Ваша корзина пуста', style: TextStyle(fontSize: 18)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return ListTile(
                        leading: item.shoe.hasValidImage
                            ? Image.network(item.shoe.imageUrl!, width: 50, errorBuilder: (c, e, s) => const Icon(Icons.image))
                            : const Icon(Icons.image, size: 50, color: Colors.grey),
                        title: Text(item.shoe.name),
                        subtitle: Text('Размер: ${item.stock.size} | Кол-во: ${item.quantity}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => cart.removeItem(item),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white, 
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Итого: ${cart.totalPrice} руб.', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      FilledButton(
                        onPressed: _isOrdering ? null : _checkout,
                        child: _isOrdering 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ) 
                            : const Text('Оформить'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}