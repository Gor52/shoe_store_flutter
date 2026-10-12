import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../state/auth_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  Uint8List? _selectedImageBytes; 
  bool _isUploadingAvatar = false;
  final ImagePicker _picker = ImagePicker();
  
  RecordModel? _profileRecord; 
  
  late TextEditingController _firstNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userModel = pb.authStore.model;
      if (userModel != null) {
        final record = await pb.collection('profiles').getFirstListItem('user_id = "${userModel.id}"');
        _profileRecord = record;
        
        _firstNameController.text = record.getStringValue('first_name');
        _phoneController.text = record.getStringValue('phone');
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final userId = pb.authStore.model!.id;
      final body = {
        'user_id': userId,
        'first_name': _firstNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      if (_profileRecord == null) {
        _profileRecord = await pb.collection('profiles').create(body: body);
      } else {
        _profileRecord = await pb.collection('profiles').update(_profileRecord!.id, body: body);
      }
      
      setState(() => _isEditing = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Данные профиля успешно обновлены')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        
        setState(() {
          _selectedImageBytes = bytes;
        });

        await _uploadAvatarToPocketBase(bytes, pickedFile.name);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка выбора фото: $e')));
    }
  }

  Future<void> _uploadAvatarToPocketBase(Uint8List bytes, String fileName) async {
    setState(() => _isUploadingAvatar = true);
    try {
      final userId = pb.authStore.model!.id;

      final multipartFile = http.MultipartFile.fromBytes(
        'avatar', 
        bytes,
        filename: fileName,
      );

      await pb.collection('users').update(
        userId,
        files: [multipartFile],
      );

      await pb.collection('users').authRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Фото профиля успешно обновлено!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthNotifier>(); 
    final userModel = pb.authStore.model;

    if (userModel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мой профиль', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle_outlined, size: 100, color: Colors.grey.shade400),
                const SizedBox(height: 24),
                const Text('Вы не авторизованы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Войдите в аккаунт, чтобы управлять своими данными', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: () => context.go('/login'), child: const Text('Войти в аккаунт'))),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () => context.go('/register'), child: const Text('Создать аккаунт'))),
              ],
            ),
          ),
        ),
      );
    }

    final email = userModel.getStringValue('email');
    final role = userModel.getStringValue('role');
    final avatar = userModel.getStringValue('avatar');
 
    final avatarUrl = avatar.isNotEmpty ? pb.files.getUrl(userModel, avatar).toString() : null;

    final loyaltyPoints = _profileRecord?.getIntValue('loyality_points') ?? 0;
    final firstName = _profileRecord?.getStringValue('first_name') ?? '';
    final phone = _profileRecord?.getStringValue('phone') ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _firstNameController.text = firstName;
                _phoneController.text = phone;
              }
              setState(() => _isEditing = !_isEditing);
            },
            tooltip: _isEditing ? 'Отменить' : 'Редактировать',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: _selectedImageBytes != null
                                ? MemoryImage(_selectedImageBytes!)
                                : (avatarUrl != null ? NetworkImage(avatarUrl) : null) as ImageProvider?,
                            child: _isUploadingAvatar
                                ? const CircularProgressIndicator(color: Colors.white)
                                : (_selectedImageBytes == null && avatarUrl == null 
                                    ? const Icon(Icons.person, size: 70, color: Colors.blue) 
                                    : null),
                          ),
                          if (_isEditing)
                            Container(
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: _isUploadingAvatar ? null : _pickAndUploadImage,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              if (_isEditing) ...[
                                TextField(
                                  controller: _firstNameController,
                                  decoration: const InputDecoration(labelText: 'Имя (first_name)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: FilledButton(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    child: _isSaving 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                                        : const Text('Сохранить изменения'),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  firstName.isNotEmpty ? firstName : 'Имя не указано',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.phone, size: 18, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(phone.isNotEmpty ? phone : 'Телефон не указан', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.email, size: 18, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(email, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.stars, color: Colors.orange.shade600, size: 32),
                                      const SizedBox(width: 12),
                                      Text(
                                        '$loyaltyPoints',
                                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('бонусов', style: TextStyle(fontSize: 16, color: Colors.orange.shade800, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Chip(
                                  label: Text(role.toUpperCase()),
                                  backgroundColor: role == 'admin' ? Colors.red.shade100 : Colors.blue.shade50,
                                  labelStyle: TextStyle(
                                    color: role == 'admin' ? Colors.red.shade900 : Colors.blue.shade900, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<AuthNotifier>().logout();
                            context.go('/login');
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text('Выйти из аккаунта', style: TextStyle(color: Colors.red, fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}