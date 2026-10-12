import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import '../core/api_client.dart';
import '../core/validators.dart';
import '../models/shoe.dart';

class ShoeFormScreen extends StatefulWidget {
  final Shoe? shoe; 

  const ShoeFormScreen({super.key, this.shoe});

  @override
  State<ShoeFormScreen> createState() => _ShoeFormScreenState();
}

class _ShoeFormScreenState extends State<ShoeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _imageController;

  String? _selectedBrandId;
  List<String> _selectedCategoryIds = []; 
  
  List<RecordModel> _brands = [];
  List<RecordModel> _categories = [];
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shoe?.name ?? '');
    _priceController = TextEditingController(text: widget.shoe != null ? widget.shoe!.price.toString() : '');
    _descController = TextEditingController(text: widget.shoe?.description ?? '');
    _imageController = TextEditingController(text: widget.shoe?.imageUrl ?? '');
    
    
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        pb.collection('brands').getFullList(sort: 'name'),
        pb.collection('categories').getFullList(sort: 'name'),
      ]);

      if (mounted) {
        setState(() {
          _brands = results[0];
          _categories = results[1];

          if (widget.shoe != null && _brands.any((b) => b.id == widget.shoe!.brandId)) {
            _selectedBrandId = widget.shoe!.brandId;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки справочников: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveShoe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите бренд')));
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите хотя бы одну категорию')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final body = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'description': _descController.text.trim(),
        'image_url': _imageController.text.trim(),
        'brand_id': _selectedBrandId,
        'categories': _selectedCategoryIds, 
      };

      if (widget.shoe == null) {
        await pb.collection('shoes').create(body: body);
      } else {
        await pb.collection('shoes').update(widget.shoe!.id, body: body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Успешно сохранено!'), backgroundColor: Colors.green));
        context.pop(); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shoe == null ? 'Добавить обувь' : 'Редактировать обувь'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Название модели', border: OutlineInputBorder()),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Введите название' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Бренд', border: OutlineInputBorder()),
                                value: _selectedBrandId,
                                items: _brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.getStringValue('name')))).toList(),
                                onChanged: (val) => setState(() => _selectedBrandId = val),
                                validator: (val) => val == null ? 'Выберите бренд' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(labelText: 'Цена (руб.)', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: AppValidators.price, 
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const Text('Категории (множественный выбор):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((category) {
                            final isSelected = _selectedCategoryIds.contains(category.id);
                            return FilterChip(
                              label: Text(category.getStringValue('name')),
                              selected: isSelected,
                              selectedColor: Colors.blue.shade100,
                              checkmarkColor: Colors.blue.shade900,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategoryIds.add(category.id);
                                  } else {
                                    _selectedCategoryIds.remove(category.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _imageController,
                          decoration: const InputDecoration(labelText: 'URL изображения', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _isSaving ? null : _saveShoe,
                            child: _isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Сохранить', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}