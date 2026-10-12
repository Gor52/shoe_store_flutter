import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart'; 
import '../models/stock.dart';
import '../models/shoe.dart';
import '../repositories/shoe_repository.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  List<Stock> _stocks = [];
  List<Shoe> _shoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ShoeRepository>();
      final stocks = await repo.getAllStocks();
      final shoes = await repo.getAllShoes();
      if (mounted) {
        setState(() {
          _stocks = stocks;
          _shoes = shoes;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showDialog({Stock? stock}) async {
    final sizeController = TextEditingController(text: stock?.size.toString() ?? '');
    final quantityController = TextEditingController(text: stock?.quantity.toString() ?? '');
    String? selectedShoeId = stock?.shoeId;

    String? sizeError;
    String? quantityError;
    String? shoeError;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            stock == null ? 'Новое поступление' : 'Редактировать остаток',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (stock == null)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Обувь', 
                        border: const OutlineInputBorder(),
                        errorText: shoeError, 
                      ),
                      value: selectedShoeId,
                      items: _shoes.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) => setStateDialog(() => selectedShoeId = val),
                      validator: (val) => val == null ? 'Выберите обувь' : null,
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: sizeController,
                    decoration: InputDecoration(
                      labelText: 'Размер (например, 42.5)', 
                      border: const OutlineInputBorder(),
                      errorText: sizeError, 
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || double.tryParse(val.trim()) == null ? 'Введите корректный размер' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: 'Количество шт.', 
                      border: const OutlineInputBorder(),
                      errorText: quantityError, 
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || int.tryParse(val.trim()) == null ? 'Введите целое число' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                setStateDialog(() {
                  sizeError = null;
                  quantityError = null;
                  shoeError = null;
                });

                if (!formKey.currentState!.validate()) return;
                
                try {
                  final size = double.parse(sizeController.text.trim());
                  final qty = int.parse(quantityController.text.trim());
                  if (stock == null) {
                    await context.read<ShoeRepository>().createStock(selectedShoeId!, size, qty);
                  } else {
                    await context.read<ShoeRepository>().updateStock(stock.id, size, qty);
                  }
                  if (context.mounted) Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  if (e is ClientException) {
                    final responseData = e.response;
                    if (responseData.containsKey('data')) {
                      final errors = responseData['data'] as Map<String, dynamic>;
                      setStateDialog(() {
                        sizeError = errors['size']?['message'];
                        quantityError = errors['quantity']?['message'];
                        shoeError = errors['shoe_id']?['message'];
                      });
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                    }
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Stock stock) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление'),
        content: const Text('Точно удалить эту позицию со склада?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Удалить')
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ShoeRepository>().deleteStock(stock.id);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Color _getQuantityColor(int quantity) {
    if (quantity == 0) return Colors.red;
    if (quantity < 5) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление складом (размеры)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Поступление'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: _stocks.length,
              itemBuilder: (context, index) {
                final stock = _stocks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          stock.size.toString().replaceAll(RegExp(r'\.0$'), ''),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                        ),
                      ),
                      title: Text(stock.shoeName ?? 'Неизвестная обувь', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Text('В наличии: '),
                            Text(
                              '${stock.quantity} шт.', 
                              style: TextStyle(
                                color: _getQuantityColor(stock.quantity),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDialog(stock: stock)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(stock)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}