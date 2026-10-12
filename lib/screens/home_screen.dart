import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/shoe_list_notifier.dart';
import '../state/auth_notifier.dart';
import '../state/cart_notifier.dart';
import 'shoe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? search;
  final String? brand;
  final String? sort;
  final int page; 

  const HomeScreen({super.key, this.search, this.brand, this.sort, this.page = 1});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.search ?? '');
   
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<ShoeListNotifier>();
      notifier.setFilter(
        search: widget.search ?? '',
        brandId: widget.brand,
        sort: widget.sort ?? '-created',
      );
      if (widget.page > 1) {
        notifier.setPage(widget.page);
      }
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Отслеживаем изменения в URL (например, при нажатии "Назад" в браузере)
    if (widget.search != oldWidget.search ||
        widget.brand != oldWidget.brand ||
        widget.sort != oldWidget.sort ||
        widget.page != oldWidget.page) {
      
      if (widget.search != _searchController.text) {
        _searchController.text = widget.search ?? '';
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = context.read<ShoeListNotifier>();
        notifier.setFilter(
          search: widget.search ?? '',
          brandId: widget.brand,
          sort: widget.sort ?? '-created',
        );
        notifier.setPage(widget.page);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String search, String? brand, String sort, {int page = 1}) {
    final queryParams = <String, String>{};
    if (search.isNotEmpty) queryParams['search'] = search;
    if (brand != null && brand.isNotEmpty) queryParams['brand'] = brand;
    if (sort != '-created') queryParams['sort'] = sort;
    if (page > 1) queryParams['page'] = page.toString();

    final uri = Uri(path: '/', queryParameters: queryParams);
    context.go(uri.toString()); 
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ShoeListNotifier>();
    final authNotifier = context.watch<AuthNotifier>();
    final isAuthenticated = authNotifier.isAuthenticated;
    final userRole = authNotifier.userRole;
    final cartItemCount = context.watch<CartNotifier>().itemCount;
    
    final isStaff = userRole == 'admin' || userRole == 'manager';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Витрина', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (!isStaff)
            IconButton(
              icon: Badge(
                label: Text(cartItemCount.toString()),
                isLabelVisible: cartItemCount > 0,
                child: const Icon(Icons.shopping_cart),
              ),
              tooltip: 'Корзина',
              // ИСПРАВЛЕНО: context.push заменен на context.go для обновления URL
              onPressed: () => context.go('/cart'),
            ),
          const SizedBox(width: 8),
          
          if (!isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                // ИСПРАВЛЕНО: context.push заменен на context.go
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: const Text('Войти', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Профиль',
              onPressed: () => context.go('/profile'),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade700),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text('Shoe Store', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Главная'),
              onTap: () { Navigator.pop(context); context.go('/'); },
            ),
            if (isAuthenticated && !isStaff)
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Мои заказы'),
                // ИСПРАВЛЕНО: context.push заменен на context.go
                onTap: () { Navigator.pop(context); context.go('/orders'); },
              ),
            if (isAuthenticated)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Профиль'),
                // ИСПРАВЛЕНО: context.push заменен на context.go
                onTap: () { Navigator.pop(context); context.go('/profile'); },
              ),
            if (isStaff)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                title: const Text('Панель управления', style: TextStyle(color: Colors.red)),
                // ИСПРАВЛЕНО: context.push заменен на context.go
                onTap: () { Navigator.pop(context); context.go('/admin'); },
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(labelText: 'Поиск по названию', border: OutlineInputBorder(), isDense: true),
                    onSubmitted: (val) => _applyFilter(val, widget.brand, widget.sort ?? '-created', page: 1),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(labelText: 'Бренд', border: OutlineInputBorder(), isDense: true),
                    value: widget.brand,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все бренды')),
                      ...notifier.availableBrands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                    ],
                    onChanged: (val) => _applyFilter(_searchController.text, val, widget.sort ?? '-created', page: 1),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Сортировка', border: OutlineInputBorder(), isDense: true),
                    value: widget.sort ?? '-created',
                    items: const [
                      DropdownMenuItem(value: '-created', child: Text('Сначала новые')),
                      DropdownMenuItem(value: 'price', child: Text('Сначала дешевые')),
                      DropdownMenuItem(value: '-price', child: Text('Сначала дорогие')),
                    ],
                    onChanged: (val) => _applyFilter(_searchController.text, widget.brand, val!, page: 1),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _applyFilter(_searchController.text, widget.brand, widget.sort ?? '-created', page: 1),
                  icon: const Icon(Icons.search),
                  label: const Text('Найти'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: switch (notifier.status) {
              LoadStatus.idle || LoadStatus.loading => const Center(child: CircularProgressIndicator()),
              LoadStatus.error => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(notifier.errorMessage ?? 'Произошла ошибка'),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: () => context.read<ShoeListNotifier>().load(), child: const Text('Повторить')),
                    ],
                  ),
                ),
              LoadStatus.success when notifier.shoes.isEmpty => const Center(child: Text('Товаров не найдено')),
              LoadStatus.success => GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    childAspectRatio: 0.75, 
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: notifier.shoes.length,
                  itemBuilder: (context, index) {
                    final shoe = notifier.shoes[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ShoeDetailScreen(shoe: shoe),
                          ));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: shoe.hasValidImage
                                  ? Image.network(shoe.imageUrl!, fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shoe.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${shoe.price} руб.',
                                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            },
          ),

          if (notifier.status == LoadStatus.success)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: widget.page > 1
                        ? () => _applyFilter(_searchController.text, widget.brand, widget.sort ?? '-created', page: widget.page - 1)
                        : null,
                  ),
                  Text('Страница ${widget.page}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: notifier.shoes.length == 10
                        ? () => _applyFilter(_searchController.text, widget.brand, widget.sort ?? '-created', page: widget.page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}