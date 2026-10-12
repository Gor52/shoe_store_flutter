import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart'; 
import '../models/user_model.dart';
import '../repositories/shoe_repository.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _selectedIds.clear();
    });
    try {
      final users = await context.read<ShoeRepository>().getAllUsers();
      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _bulkDeleteUsers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Множественное удаление'),
        content: Text('Точно удалить выбранных пользователей (${_selectedIds.length})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Удалить')
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ShoeRepository>().deleteMultipleUsers(_selectedIds.toList());
        _loadUsers();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _bulkBanUsers() async {
    try {
      for (final id in _selectedIds) {
        await context.read<ShoeRepository>().updateUserByAdmin(id, '', '', 'banned');
      }
      _loadUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка блокировки: $e')));
    }
  }

  Future<void> _showUserDialog({UserModel? user}) async {
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController(); 
    String selectedRole = user?.role.isNotEmpty == true ? user!.role : 'buyer';

    String? nameError;
    String? emailError;
    String? passwordError;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(user == null ? 'Новый пользователь' : 'Редактировать пользователя'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Имя',
                      errorText: nameError, 
                    ),
                    validator: (val) => val!.trim().isEmpty ? 'Введите имя' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: emailError, 
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val!.trim().isEmpty ? 'Введите email' : null,
                  ),
                  const SizedBox(height: 16),
                  if (user == null) ...[
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Пароль (минимум 8 символов)',
                        errorText: passwordError, 
                      ),
                      obscureText: true,
                      validator: (val) => val != null && val.length < 8 ? 'Минимум 8 символов' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Роль'),
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'buyer', child: Text('Покупатель')),
                      DropdownMenuItem(value: 'manager', child: Text('Менеджер')),
                      DropdownMenuItem(value: 'admin', child: Text('Администратор')),
                      DropdownMenuItem(value: 'banned', child: Text('Заблокирован')),
                    ],
                    onChanged: (val) => setStateDialog(() => selectedRole = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                setStateDialog(() {
                  nameError = null;
                  emailError = null;
                  passwordError = null;
                });

                if (!formKey.currentState!.validate()) return;
                
                try {
                  if (user == null) {
                    await context.read<ShoeRepository>().createUserByAdmin(
                      nameController.text.trim(),
                      emailController.text.trim(),
                      passwordController.text,
                      selectedRole,
                    );
                  } else {
                    await context.read<ShoeRepository>().updateUserByAdmin(
                      user.id,
                      nameController.text.trim(),
                      emailController.text.trim(),
                      selectedRole,
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                  _loadUsers();
                } catch (e) {
                  if (e is ClientException) {
                    final responseData = e.response;
                    if (responseData.containsKey('data')) {
                      final errors = responseData['data'] as Map<String, dynamic>;
                      setStateDialog(() {
                        nameError = errors['name']?['message'];
                        emailError = errors['email']?['message'];
                        passwordError = errors['password']?['message'];
                      });
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                    }
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление'),
        content: Text('Точно удалить пользователя "${user.email}"? Это действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Удалить')
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ShoeRepository>().deleteUser(user.id);
        _loadUsers();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIds.isNotEmpty ? 'Выбрано: ${_selectedIds.length}' : 'Управление пользователями'),
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.block, color: Colors.orange),
              tooltip: 'Заблокировать выбранных',
              onPressed: _bulkBanUsers,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить выбранных',
              onPressed: _bulkDeleteUsers,
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isSelected = _selectedIds.contains(user.id);
                
                Color roleColor = Colors.grey;
                if (user.role == 'admin') roleColor = Colors.red;
                if (user.role == 'manager') roleColor = Colors.orange;
                if (user.role == 'buyer') roleColor = Colors.blue;
                if (user.role == 'banned') roleColor = Colors.black54;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(user.id);
                              } else {
                                _selectedIds.remove(user.id);
                              }
                            });
                          },
                        ),
                        CircleAvatar(
                          backgroundColor: roleColor.withOpacity(0.2),
                          child: Icon(Icons.person, color: roleColor),
                        ),
                      ],
                    ),
                    title: Text(user.name.isEmpty ? 'Без имени' : user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(user.role.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showUserDialog(user: user)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(user)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}