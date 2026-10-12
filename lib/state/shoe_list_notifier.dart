import 'package:flutter/foundation.dart';
import '../models/shoe.dart';
import '../models/brand.dart';
import '../repositories/shoe_repository.dart';

enum LoadStatus { idle, loading, success, error }

class ShoeListNotifier extends ChangeNotifier {
  final ShoeRepository _repository;
  
  ShoeListNotifier(this._repository);

  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  List<Shoe> _shoes = [];

  int _currentPage = 1;
  String _searchQuery = '';
  String? _selectedBrandId;
  String _sortOption = '-created';
  
  List<Brand> _availableBrands = [];

  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<Shoe> get shoes => List.unmodifiable(_shoes);
  
  int get currentPage => _currentPage;
  String get searchQuery => _searchQuery;
  String? get selectedBrandId => _selectedBrandId;
  String get sortOption => _sortOption;
  List<Brand> get availableBrands => _availableBrands;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_availableBrands.isEmpty) {
        _availableBrands = await _repository.getBrands();
      }

      _shoes = await _repository.getShoesPaginated(
        page: _currentPage,
        search: _searchQuery,
        brandId: _selectedBrandId,
        sort: _sortOption,
      );
      _status = LoadStatus.success;
    } catch (e) {
      _errorMessage = 'Не удалось загрузить каталог: $e';
      _status = LoadStatus.error;
    }
    
    notifyListeners();
  }

  void setFilter({
    required String search, 
    required String? brandId, 
    required String sort,
  }) {
    _searchQuery = search;
    _selectedBrandId = brandId; 
    _sortOption = sort;
    _currentPage = 1; 
    load();
  }

  void setPage(int page) {
    _currentPage = page;
    load();
  }

  Future<void> remove(String id) async {
    try {
      await _repository.deleteShoe(id);
      _shoes.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка удаления: $e';
      _status = LoadStatus.error;
      notifyListeners();
    }
  }
}