import 'package:pocketbase/pocketbase.dart';

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromRecord(RecordModel record) {
    return Category(
      id: record.id,
      name: record.getStringValue('name'),
    );
  }
}