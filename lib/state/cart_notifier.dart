import 'package:flutter/material.dart';
import '../models/shoe.dart';
import '../models/stock.dart';

class CartItem {
  final Shoe shoe;
  final Stock stock;
  int quantity;

  CartItem({required this.shoe, required this.stock, this.quantity = 1});
}

class CartNotifier extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get totalPrice => _items.fold(0, (total, item) => total + (item.shoe.price * item.quantity));
  int get itemCount => _items.fold(0, (count, item) => count + item.quantity);

  void addItem(Shoe shoe, Stock stock) {
    final index = _items.indexWhere((i) => i.shoe.id == shoe.id && i.stock.id == stock.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(shoe: shoe, stock: stock));
    }
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}