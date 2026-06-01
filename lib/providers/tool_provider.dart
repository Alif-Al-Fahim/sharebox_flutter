import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/recommendation_service.dart';
import '../models/tool_model.dart';

class ToolProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final RecommendationService _recommendationService = RecommendationService();

  List<ToolModel> _tools = [];
  List<ToolModel> _filteredTools = [];
  List<ToolModel> _myTools = [];
  List<ToolModel> _recommendedTools = [];
  List<ToolModel> _favoriteTools = [];

  ToolCategory? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;
  double _uploadProgress = 0;

  List<ToolModel> get tools => _filteredTools.isEmpty && _searchQuery.isEmpty
      ? _tools
      : _filteredTools;
  List<ToolModel> get myTools => _myTools;
  List<ToolModel> get recommendedTools => _recommendedTools;
  List<ToolModel> get favoriteTools => _favoriteTools;
  ToolCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  // Stream available tools
  void loadAvailableTools() {
    _firestoreService.streamAvailableTools().listen((tools) {
      _tools = tools;
      _applyFilters();
      notifyListeners();
    });
  }

  // Stream user's tools
  void loadMyTools(String userId) {
    _firestoreService.streamToolsByOwner(userId).listen((tools) {
      _myTools = tools;
      notifyListeners();
    });
  }

  // Stream favorite tools
  void loadFavoriteTools(String userId) {
    _firestoreService.streamFavoriteTools(userId).listen((tools) {
      _favoriteTools = tools;
      notifyListeners();
    });
  }

  // Load recommended tools
  Future<void> loadRecommendedTools(String userId) async {
    try {
      _recommendedTools =
          await _recommendationService.getRecommendedTools(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    }
  }

  // Search tools
  Future<void> searchTools(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _applyFilters();
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final results = await _firestoreService.searchTools(query);
      _filteredTools = results;
    } catch (e) {
      _error = 'Search failed. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  // Filter by category
  void filterByCategory(ToolCategory? category) {
    _selectedCategory = category;
    if (category == null) {
      _filteredTools = _tools;
    } else {
      _filteredTools = _tools
          .where((t) => t.category == category)
          .toList();
    }
    notifyListeners();
  }

  // Add a new tool
  Future<String?> addTool({
    required String name,
    required ToolCategory category,
    required double pricePerDay,
    required String description,
    required String location,
    required String ownerId,
    required String ownerName,
    String? ownerImage,
    required List<File> imageFiles,
  }) async {
    _setUploading(true);
    _clearError();
    try {
      // Upload images first
      final imageUrls = <String>[];
      for (int i = 0; i < imageFiles.length; i++) {
        final url = await _storageService.uploadToolImage(
          ownerId: ownerId,
          imageFile: imageFiles[i],
        );
        imageUrls.add(url);
        _uploadProgress = (i + 1) / imageFiles.length;
        notifyListeners();
      }

      final tool = ToolModel(
        id: '',
        name: name,
        category: category,
        pricePerDay: pricePerDay,
        description: description,
        images: imageUrls,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerImage: ownerImage,
        location: location,
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      final toolId = await _firestoreService.addTool(tool);
      return toolId;
    } catch (e) {
      _error = 'Failed to add tool. Please try again.';
      return null;
    } finally {
      _setUploading(false);
      _uploadProgress = 0;
    }
  }

  // Update tool
  Future<bool> updateTool(String toolId, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();
    try {
      await _firestoreService.updateTool(toolId, data);
      return true;
    } catch (e) {
      _error = 'Failed to update tool.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete tool
  Future<bool> deleteTool(String toolId, List<String> imageUrls) async {
    _setLoading(true);
    _clearError();
    try {
      await _storageService.deleteImages(imageUrls);
      await _firestoreService.deleteTool(toolId);
      return true;
    } catch (e) {
      _error = 'Failed to delete tool.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle tool availability
  Future<void> toggleAvailability(String toolId, bool isAvailable) async {
    await _firestoreService.toggleToolAvailability(toolId, isAvailable);
  }

  // Toggle favorite
  Future<void> toggleFavorite(String userId, String toolId) async {
    await _firestoreService.toggleFavoriteTool(userId, toolId);
  }

  bool isFavorite(String toolId) {
    return _favoriteTools.any((t) => t.id == toolId);
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  void _applyFilters() {
    if (_selectedCategory != null) {
      _filteredTools = _tools.where((t) => t.category == _selectedCategory).toList();
    } else {
      _filteredTools = _tools;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredTools = _tools;
    notifyListeners();
  }
}
