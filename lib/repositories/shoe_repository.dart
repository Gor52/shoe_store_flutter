import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../models/shoe.dart';
import '../models/brand.dart';
import '../models/stock.dart';
import '../models/order.dart';
import '../models/category.dart';
import '../models/review.dart';
import '../models/user_model.dart';

class ShoeRepository {
  Future<List<Shoe>> getShoes() async {
    final records = await pb.collection('shoes').getFullList(
      filter: 'is_deleted = false',
      expand: 'brand_id,category_id', 
    );
    return records.map((record) => Shoe.fromRecord(record)).toList();
  }

  Future<List<Shoe>> getShoesPaginated({
    int page = 1,
    int perPage = 10,
    String search = '',
    String? brandId,
    String sort = '-created', 
  }) async {
    List<String> filters = ['is_deleted = false'];
    
    if (search.isNotEmpty) {
      filters.add('name ~ "$search"');
    }
    if (brandId != null && brandId.isNotEmpty) {
      filters.add('brand_id = "$brandId"');
    }

    final filterString = filters.join(' && ');

    final result = await pb.collection('shoes').getList(
      page: page,
      perPage: perPage,
      filter: filterString,
      sort: sort,
      expand: 'brand_id,category_id',
    );
    
    return result.items.map((record) => Shoe.fromRecord(record)).toList();
  }

  Future<List<Shoe>> getAllShoes() async {
    final records = await pb.collection('shoes').getFullList(filter: 'is_deleted = false', expand: 'brand_id,category_id');
    return records.map((record) => Shoe.fromRecord(record)).toList();
  }

  Future<List<Shoe>> getAllShoesAdmin() async {
    final records = await pb.collection('shoes').getFullList(sort: '-created', expand: 'brand_id,category_id');
    return records.map((record) => Shoe.fromRecord(record)).toList();
  }

  Future<void> createShoe(
    String name, 
    double price, 
    String brandId, 
    List<String> categoryIds, {
    Uint8List? imageBytes, 
    String? imageName,
  }) async {
    final body = <String, dynamic>{
      "name": name,
      "price": price,
      "brand_id": brandId,
      "category_id": categoryIds,
      "is_deleted": false,
    };

    List<http.MultipartFile> files = [];
    if (imageBytes != null && imageName != null) {
      files.add(http.MultipartFile.fromBytes('images', imageBytes, filename: imageName));
    }

    await pb.collection('shoes').create(body: body, files: files);
  }

  Future<void> updateShoe(
    String id, 
    String name, 
    double price, 
    String brandId, 
    List<String> categoryIds, {
    Uint8List? imageBytes, 
    String? imageName,
  }) async {
    final body = <String, dynamic>{
      "name": name,
      "price": price,
      "brand_id": brandId,
      "category_id": categoryIds,
    };

    List<http.MultipartFile> files = [];
    if (imageBytes != null && imageName != null) {
      files.add(http.MultipartFile.fromBytes('images', imageBytes, filename: imageName));
    }

    await pb.collection('shoes').update(id, body: body, files: files);
  }

  Future<void> deleteShoe(String id) async {
    final body = <String, dynamic>{
      "is_deleted": true,
    };
    await pb.collection('shoes').update(id, body: body);
  }

  Future<void> restoreShoe(String id) async {
    await pb.collection('shoes').update(id, body: {"is_deleted": false});
  }

  Future<List<Brand>> getBrands() async {
    final records = await pb.collection('brands').getFullList();
    return records.map((record) => Brand.fromRecord(record)).toList();
  }

  Future<void> createBrand(String name, String country, {
    Uint8List? imageBytes, 
    String? imageName,
  }) async {
    final body = {
      'name': name,
      'country': country, 
    };
    
    List<http.MultipartFile> files = [];
    if (imageBytes != null && imageName != null) {
      files.add(http.MultipartFile.fromBytes('logo', imageBytes, filename: imageName));
    }

    await pb.collection('brands').create(body: body, files: files);
  }

  Future<void> updateBrand(String id, String name, String country, {
    Uint8List? imageBytes, 
    String? imageName,
  }) async {
    final body = {
      'name': name,
      'country': country, 
    };
    
    List<http.MultipartFile> files = [];
    if (imageBytes != null && imageName != null) {
      files.add(http.MultipartFile.fromBytes('logo', imageBytes, filename: imageName));
    }

    await pb.collection('brands').update(id, body: body, files: files);
  }

  Future<void> deleteBrand(String id) async {
    await pb.collection('brands').delete(id); 
  }

  Future<List<Category>> getCategories() async {
    final records = await pb.collection('categories').getFullList();
    return records.map((record) => Category.fromRecord(record)).toList();
  }

  Future<void> createCategory(String name) async {
    await pb.collection('categories').create(body: {'name': name});
  }

  Future<void> updateCategory(String id, String name) async {
    await pb.collection('categories').update(id, body: {'name': name});
  }

  Future<void> deleteCategory(String id) async {
    await pb.collection('categories').delete(id);
  }

  Future<List<Stock>> getStocksForShoe(String shoeId) async {
    final records = await pb.collection('stocks').getFullList(
      filter: 'shoe_id = "$shoeId" && quantity > 0', 
      sort: 'size', 
    );
    return records.map((record) => Stock.fromRecord(record)).toList();
  }

  Future<List<Stock>> getAllStocks() async {
    final records = await pb.collection('stocks').getFullList(expand: 'shoe_id');
    return records.map((record) => Stock.fromRecord(record)).toList();
  }

  Future<void> createStock(String shoeId, double size, int quantity) async {
    await pb.collection('stocks').create(body: {'shoe_id': shoeId, 'size': size, 'quantity': quantity});
  }

  Future<void> updateStock(String id, double size, int quantity) async {
    await pb.collection('stocks').update(id, body: {'size': size, 'quantity': quantity});
  }

  Future<void> deleteStock(String id) async {
    await pb.collection('stocks').delete(id);
  }

  Future<void> placeOrder({
    required String userId,
    required String shoeId,
    required String stockId,
    required double price,
  }) async {
    final stockRecord = await pb.collection('stocks').getOne(stockId);
    final currentQuantity = stockRecord.getIntValue('quantity');
    
    if (currentQuantity <= 0) {
      throw Exception('Извините, этот размер только что закончился.');
    }

    final order = await pb.collection('orders').create(body: {
      'user_id': userId,
      'total_amount': price,
      'status': 'pending',
    });

    await pb.collection('order_items').create(body: {
      'order_id': order.id,
      'shoe_id': shoeId,
      'stock_id': stockId,
      'quantity': 1,
      'price': price,
    });

    await pb.collection('stocks').update(stockId, body: {
      'quantity': currentQuantity - 1,
    });
  }

  Future<List<Order>> getUserOrders(String userId) async {
    final records = await pb.collection('orders').getFullList(
      filter: 'user_id = "$userId"',
      sort: '-created', 
    );
    return records.map((record) => Order.fromRecord(record)).toList();
  }

  Future<List<Order>> getAllOrders() async {
    final records = await pb.collection('orders').getFullList(
      sort: '-created',
      expand: 'user_id', 
    );
    return records.map((record) => Order.fromRecord(record)).toList();
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await pb.collection('orders').update(id, body: {'status': status});
  }

  Future<List<Review>> getReviewsForShoe(String shoeId) async {
    final records = await pb.collection('reviews').getFullList(
      filter: 'shoe_id = "$shoeId"',
      sort: '-created', 
      expand: 'user_id', 
    );
    return records.map((record) => Review.fromRecord(record)).toList();
  }

  Future<void> createReview(String shoeId, String userId, int rating, String text) async {
    await pb.collection('reviews').create(body: {
      'shoe_id': shoeId,
      'user_id': userId,
      'rating': rating,
      'comment': text,
    });
  }

  Future<void> deleteReview(String reviewId) async {
    await pb.collection('reviews').delete(reviewId);
  }

  Future<List<UserModel>> getAllUsers() async {
    final records = await pb.collection('users').getFullList(sort: '-created');
    return records.map((record) => UserModel.fromRecord(record)).toList();
  }

  Future<void> createUserByAdmin(String name, String email, String password, String role) async {
    await pb.collection('users').create(body: {
      'name': name,
      'email': email,
      'password': password,
      'passwordConfirm': password,
      'role': role,
      'emailVisibility': true,
    });
  }

  Future<void> updateUserByAdmin(String id, String name, String email, String role) async {
    await pb.collection('users').update(id, body: {
      'name': name,
      'email': email,
      'role': role,
    });
  }

  Future<void> deleteUser(String id) async {
    await pb.collection('users').delete(id);
  }
  
  Future<void> deleteMultipleShoes(List<String> ids) async {
    for (final id in ids) {
      await pb.collection('shoes').update(id, body: {"is_deleted": true});
    }
  }

  Future<void> restoreMultipleShoes(List<String> ids) async {
    for (final id in ids) {
      await pb.collection('shoes').update(id, body: {"is_deleted": false});
    }
  }
  Future<void> hardDeleteShoe(String id) async {
    await pb.collection('shoes').delete(id);
  }

  Future<void> hardDeleteMultipleShoes(List<String> ids) async {
    for (final id in ids) {
      await pb.collection('shoes').delete(id);
    }
  }

  Future<void> deleteMultipleBrands(List<String> ids) async {
    for (final id in ids) {
      await pb.collection('brands').delete(id);
    }
  }

  Future<void> deleteMultipleCategories(List<String> ids) async {
    for (final id in ids) {
      await pb.collection('categories').delete(id);
    }
  }

  Future<void> deleteMultipleUsers(List<String> ids) async {
    for (final id in ids) {
      await pb.collection('users').delete(id);
    }
  }

  Future<void> banUser(String id) async {
    await pb.collection('users').update(id, body: {'role': 'banned'});
  }

  Future<void> banMultipleUsers(List<String> ids) async {
    for (final id in ids) {
      await pb.collection('users').update(id, body: {'role': 'banned'});
    }
  }
  Future<void> createCompleteOrder({
  required String userId,
  required List<Map<String, dynamic>> cartItems, 
}) async {

  double totalAmount = cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));

  final orderRecord = await pb.collection('orders').create(body: {
    "user_id": userId,
    "total_amount": totalAmount,
    "status": "pending",
  });

  final orderId = orderRecord.id;

  for (final item in cartItems) {
    await pb.collection('order_items').create(body: {
      "order_id": orderId,         
      "stock_id": item['stockId'], 
      "quantity": item['quantity'],
      "price_at_purchase": item['price'],
    });
  }
}
}