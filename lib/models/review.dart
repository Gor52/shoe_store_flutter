import 'package:pocketbase/pocketbase.dart';

class Review {
  final String id;
  final String shoeId;
  final String userId;
  final int rating;
  final String text;
  final DateTime created;
  final String? userEmail;

  Review({
    required this.id,
    required this.shoeId,
    required this.userId,
    required this.rating,
    required this.text,
    required this.created,
    this.userEmail,
  });

  factory Review.fromRecord(RecordModel record) {
    String? email;
    if (record.expand.containsKey('user_id')) {
      final users = record.expand['user_id'];
      if (users != null && users.isNotEmpty) {
        email = users.first.getStringValue('email');
      }
    }

    return Review(
      id: record.id,
      shoeId: record.getStringValue('shoe_id'),
      userId: record.getStringValue('user_id'),
      rating: record.getIntValue('rating'),
      text: record.getStringValue('comment'),
      created: DateTime.parse(record.getStringValue('created')),
      userEmail: email,
    );
  }
}