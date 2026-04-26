import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';

enum ViewState { idle, loading, error }

class MedicineProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<Medicine> _medicines = [];
  List<Medicine> _filtered = [];
  ViewState _state = ViewState.idle;
  String _errorMessage = '';
  String _searchQuery = '';

  List<Medicine> get medicines => _filtered;
  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  Future<void> fetchMedicines() async {
    _state = ViewState.loading;
    notifyListeners();
    try {
      _medicines = await _api.getMedicines();
      _applySearch();
      _state = ViewState.idle;
    } catch (e) {
      _errorMessage = 'Gagal memuat data obat';
      _state = ViewState.error;
    }
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filtered = List.from(_medicines);
    } else {
      _filtered = _medicines.where((m) {
        return m.name.toLowerCase().contains(_searchQuery) ||
            m.category.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> addMedicine(Medicine medicine) async {
    await _api.addMedicine(medicine);
    await fetchMedicines();
  }

  Future<void> updateMedicine(int id, Medicine medicine) async {
    await _api.updateMedicine(id, medicine);
    await fetchMedicines();
  }

  Future<void> deleteMedicine(int id) async {
    await _api.deleteMedicine(id);
    await fetchMedicines();
  }
}
