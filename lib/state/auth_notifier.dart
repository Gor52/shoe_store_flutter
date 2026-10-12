import 'package:flutter/material.dart';
import '../core/api_client.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    pb.authStore.onChange.listen((e) {
      notifyListeners();
    });
  }

  bool get isAuthenticated => pb.authStore.isValid;

  String get userRole {
    if (!isAuthenticated || pb.authStore.model == null) return 'guest';
    return pb.authStore.model!.getStringValue('role');
  }

  Future<void> login(String email, String password) async {
    await pb.collection('users').authWithPassword(email, password);
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final body = <String, dynamic>{
        "email": email,
        "emailVisibility": true,
        "password": password,
        "passwordConfirm": password,
        "name": name,
        "role": "buyer", 
      };

      await pb.collection('users').create(body: body);
      await login(email, password);
    } catch (e) {
      throw Exception('Ошибка регистрации: $e');
    }
  }

  Future<void> updateProfile(String userId, String name) async {
    try {
      final record = await pb.collection('users').update(userId, body: {
        'name': name,
      });

      pb.authStore.save(pb.authStore.token, record);
      notifyListeners();
    } catch (e) {
      throw Exception('Ошибка обновления профиля: $e');
    }
  }

  void logout() {
    pb.authStore.clear(); 
  }
}