import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/shoe.dart';
import '../models/stock.dart';
import '../models/review.dart';
import '../repositories/shoe_repository.dart';
import '../state/auth_notifier.dart';
import '../state/cart_notifier.dart';
import '../core/api_client.dart';

class ShoeDetailScreen extends StatefulWidget {
  final Shoe shoe;

  const ShoeDetailScreen({super.key, required this.shoe});

  @override
  State<ShoeDetailScreen> createState() => _ShoeDetailScreenState();
}

class _ShoeDetailScreenState extends State<ShoeDetailScreen> {
  List<Stock> _stocks = [];
  List<Review> _reviews = [];
  bool _isLoading = true;
  Stock? _selectedStock;

  final _reviewController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<ShoeRepository>();
      final stocks = await repo.getStocksForShoe(widget.shoe.id);
      final reviews = await repo.getReviewsForShoe(widget.shoe.id);
      if (mounted) {
        setState(() {
          _stocks = stocks;
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) return;
    setState(() => _isSubmittingReview = true);
    try {
      final userId = pb.authStore.model!.id;
      await context.read<ShoeRepository>().createReview(
        widget.shoe.id,
        userId,
        _selectedRating,
        _reviewController.text.trim(),
      );
      _reviewController.clear();
      _selectedRating = 5;
      await _loadData(); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление отзыва'),
        content: const Text('Точно удалить этот отзыв?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ShoeRepository>().deleteReview(reviewId);
        _loadData(); 
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final isAuthenticated = authNotifier.isAuthenticated;
    final userRole = authNotifier.userRole;
    
    final isStaff = userRole == 'admin' || userRole == 'manager';

    return Scaffold(
      appBar: AppBar(title: Text(widget.shoe.name)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: widget.shoe.hasValidImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(widget.shoe.imageUrl!, fit: BoxFit.cover),
                                  )
                                : Container(
                                    height: 300,
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                                    child: const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.shoe.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (widget.shoe.brandName != null && widget.shoe.brandName!.isNotEmpty)
                                      Chip(
                                        avatar: const Icon(Icons.branding_watermark, size: 16, color: Colors.blue),
                                        label: Text(widget.shoe.brandName!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                        backgroundColor: Colors.blue.shade50,
                                        side: BorderSide.none,
                                      ),
                                    ...widget.shoe.categoryNames.map((catName) => Chip(
                                      avatar: const Icon(Icons.category, size: 16, color: Colors.green),
                                      label: Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      backgroundColor: Colors.green.shade50,
                                      side: BorderSide.none,
                                    )),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                Text('${widget.shoe.price} руб.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue)),
                                const SizedBox(height: 32),
                                const Text('Выберите размер:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if (_stocks.isEmpty)
                                  const Text('Нет в наличии', style: TextStyle(color: Colors.red, fontSize: 16))
                                else
                                  Wrap(
                                    spacing: 8,
                                    children: _stocks.map((stock) {
                                      final isSelected = _selectedStock?.id == stock.id;
                                      return ChoiceChip(
                                        label: Text(stock.size.toString()),
                                        selected: isSelected,
                                        onSelected: (selected) => setState(() => _selectedStock = selected ? stock : null),
                                      );
                                    }).toList(),
                                  ),
                                const SizedBox(height: 32),
                                
                                if (!isStaff) ...[
                                  if (isAuthenticated)
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: FilledButton.icon(
                                        onPressed: _selectedStock == null
                                            ? null
                                            : () {
                                                context.read<CartNotifier>().addItem(widget.shoe, _selectedStock!);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Товар добавлен в корзину'), backgroundColor: Colors.green),
                                                );
                                              },
                                        icon: const Icon(Icons.add_shopping_cart),
                                        label: const Text('Добавить в корзину', style: TextStyle(fontSize: 16)),
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: () => context.push('/login'),
                                        icon: const Icon(Icons.lock_outline),
                                        label: const Text('Войти для добавления', style: TextStyle(fontSize: 16)),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 64, thickness: 1),
                      Text('Отзывы покупателей', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (isAuthenticated)
                        Card(
                          elevation: 0,
                          color: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Оставить отзыв', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Оценка: '),
                                    DropdownButton<int>(
                                      value: _selectedRating,
                                      items: [1, 2, 3, 4, 5].map((r) => DropdownMenuItem(value: r, child: Text('★ $r'))).toList(),
                                      onChanged: (val) => setState(() => _selectedRating = val!),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _reviewController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(hintText: 'Ваш отзыв...', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(
                                    onPressed: _isSubmittingReview ? null : _submitReview,
                                    child: _isSubmittingReview 
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                        : const Text('Отправить отзыв'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (_reviews.isEmpty)
                        const Text('Пока нет отзывов.')
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Row(
                                children: [
                                  Text(review.userEmail?.split('@').first ?? 'Аноним', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text('★ ${review.rating}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(review.text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                              ),
                              trailing: isStaff
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteReview(review.id),
                                    )
                                  : null,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}