import 'package:pocketbase/pocketbase.dart';

class Order {
  final String id;
  final double totalAmount;
  final String status;
  final DateTime created;
  final String? userEmail;
  final String? userName; 

  Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.created,
    this.userEmail,
    this.userName,
  });

  factory Order.fromRecord(RecordModel record) {
    String? email;
    String? name;
  
    if (record.expand.containsKey('user_id')) {
      final users = record.expand['user_id'];
      if (users != null && users.isNotEmpty) {
        email = users.first.getStringValue('email');
        name = users.first.getStringValue('name'); 
      }
    }

    return Order(
      id: record.id,
      totalAmount: record.getDoubleValue('total_amount'),
      status: record.getStringValue('status'),
      created: DateTime.parse(record.getStringValue('created')),
      userEmail: email,
      userName: name,
    );
  }
}