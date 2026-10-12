import 'package:pocketbase/pocketbase.dart';

class Stock {
  final String id;
  final String shoeId;
  final double size;
  final int quantity;
  final String? shoeName; 

  Stock({
    required this.id,
    required this.shoeId,
    required this.size,
    required this.quantity,
    this.shoeName,
  });

  factory Stock.fromRecord(RecordModel record) {
    String? sName;
    if (record.expand.containsKey('shoe_id')) {
      final shoes = record.expand['shoe_id'];
      if (shoes != null && shoes.isNotEmpty) {
        sName = shoes.first.getStringValue('name');
      }
    }

    return Stock(
      id: record.id,
      shoeId: record.getStringValue('shoe_id'),
      size: record.getDoubleValue('size'),
      quantity: record.getIntValue('quantity'),
      shoeName: sName,
    );
  }
}