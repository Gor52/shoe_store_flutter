import 'package:pocketbase/pocketbase.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime created;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.created,
  });

  factory UserModel.fromRecord(RecordModel record) {
    return UserModel(
      id: record.id,
      name: record.getStringValue('name'),
      email: record.getStringValue('email'),
      role: record.getStringValue('role'),
      created: DateTime.parse(record.getStringValue('created')),
    );
  }
}