import 'package:pocketbase/pocketbase.dart';
import '../core/api_client.dart'; 

class Shoe {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? description;
  final String? brandId;
  final String? brandName;     
  final List<String> categoryIds;    
  final List<String> categoryNames;  
  final bool isDeleted;

  Shoe({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
    this.brandId,
    this.brandName,
    this.categoryIds = const [],
    this.categoryNames = const [],
    this.isDeleted = false,
  });

  bool get hasValidImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  factory Shoe.fromRecord(RecordModel record) {
    final fileNames = record.getListValue<String>('images');
    final fileName = fileNames.isNotEmpty ? fileNames.first : '';
    
    String? fullUrl;
    if (fileName.isNotEmpty) {
      fullUrl = pb.files.getUrl(record, fileName).toString(); 
    }

    String? parsedBrandName;
    if (record.expand.containsKey('brand_id')) {
      final expandedBrand = record.expand['brand_id'];
      if (expandedBrand != null && expandedBrand.isNotEmpty) {
        parsedBrandName = expandedBrand.first.getStringValue('name');
      }
    }

    List<String> parsedCategoryNames = [];
    if (record.expand.containsKey('category_id')) {
      final expandedCategories = record.expand['category_id'];
      if (expandedCategories != null && expandedCategories.isNotEmpty) {
        parsedCategoryNames = expandedCategories.map((e) => e.getStringValue('name')).toList();
      }
    }

    return Shoe(
      id: record.id,
      name: record.getStringValue('name'),
      price: record.getDoubleValue('price'),
      imageUrl: fullUrl,
      description: record.getStringValue('description'),
      brandId: record.getStringValue('brand_id'),
      brandName: parsedBrandName,
      categoryIds: record.getListValue<String>('category_id'),
      categoryNames: parsedCategoryNames,
      isDeleted: record.getBoolValue('is_deleted'),
    );
  }
}