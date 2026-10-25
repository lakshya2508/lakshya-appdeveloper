import 'package:flutter/foundation.dart';

import '../data/virtual_tryon_service.dart';
import '../models/virtual_tryon_model.dart';

class VirtualTryOnController extends ChangeNotifier {
  VirtualTryOnController({VirtualTryOnService? service})
      : _service = service ?? VirtualTryOnService();

  final VirtualTryOnService _service;

  final List<TryOnItem> _catalog = List.from(TryOnItem.catalog);
  TryOnCategory _selectedCategory = TryOnCategory.all;
  late TryOnItem _selectedItem;

  String? _personImage;
  TryOnSession? _activeSession;
  List<TryOnSession> _history = [];

  bool _isProcessing = false;
  double _progress = 0.0;
  String _progressStage = '';
  String? _errorMessage;

  double _comparisonSlider = 0.5;
  String _viewMode = 'tryon'; // 'tryon' or '3d'
  String _endpointUrl = '';
  String _apiToken = '';
  bool _initialized = false;

  // Pre-configured sample person avatars for instant testing
  static const List<Map<String, String>> sampleModels = [
    {
      'id': 'model_alex',
      'name': 'Alex (Front Portrait)',
      'asset': 'assets/sunglasses.png', // Or placeholder
      'desc': 'Neutral studio lighting, centered pose',
    },
    {
      'id': 'model_priya',
      'name': 'Priya (Casual Standing)',
      'asset': 'assets/shoes.png',
      'desc': 'Natural daylight, head-to-toe frame',
    },
    {
      'id': 'model_jordan',
      'name': 'Jordan (Athletic Pose)',
      'asset': 'assets/helmet.png',
      'desc': 'High-contrast studio, profile angle',
    },
  ];

  // Getters
  bool get initialized => _initialized;
  List<TryOnItem> get catalog => _catalog;
  TryOnCategory get selectedCategory => _selectedCategory;
  TryOnItem get selectedItem => _selectedItem;
  String? get personImage => _personImage;
  TryOnSession? get activeSession => _activeSession;
  List<TryOnSession> get history => _history;
  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get progressStage => _progressStage;
  String? get errorMessage => _errorMessage;
  double get comparisonSlider => _comparisonSlider;
  String get viewMode => _viewMode;
  String get endpointUrl => _endpointUrl;
  String get apiToken => _apiToken;

  List<TryOnItem> get filteredCatalog {
    if (_selectedCategory == TryOnCategory.all) return _catalog;
    return _catalog.where((item) => item.category == _selectedCategory).toList();
  }

  double _garmentCantAngle = 0.0; // degrees (-45° to +45°)
  double _garmentOffsetY = 0.0;   // px (-120 to +120)
  double _garmentOffsetX = 0.0;   // px (-120 to +120)
  double _garmentScale = 1.0;     // scale (0.5 to 1.8)

  double get garmentCantAngle => _garmentCantAngle;
  double get garmentOffsetY => _garmentOffsetY;
  double get garmentOffsetX => _garmentOffsetX;
  double get garmentScale => _garmentScale;

  void setGarmentCantAngle(double angle) {
    _garmentCantAngle = angle.clamp(-45.0, 45.0);
    notifyListeners();
  }

  void setGarmentOffsetY(double y) {
    _garmentOffsetY = y.clamp(-120.0, 120.0);
    notifyListeners();
  }

  void setGarmentOffsetX(double x) {
    _garmentOffsetX = x.clamp(-120.0, 120.0);
    notifyListeners();
  }

  void setGarmentScale(double scale) {
    _garmentScale = scale.clamp(0.4, 2.0);
    notifyListeners();
  }

  void resetGarmentPlacement() {
    _garmentCantAngle = 0.0;
    _garmentOffsetY = 0.0;
    _garmentOffsetX = 0.0;
    _garmentScale = 1.0;
    notifyListeners();
  }

  Future<void> init() async {
    if (_initialized) return;

    final custom = await _service.loadCustomItems();
    for (final c in custom) {
      if (!_catalog.any((i) => i.id == c.id)) {
        _catalog.insert(0, c);
      }
    }

    _selectedItem = _catalog.first;
    _personImage = sampleModels.first['asset'];

    final savedEp = await _service.getSavedEndpoint();
    if (savedEp != null) _endpointUrl = savedEp;

    final savedTk = await _service.getSavedToken();
    if (savedTk != null) _apiToken = savedTk;

    _history = await _service.loadSessions();
    _initialized = true;
    notifyListeners();
  }

  void selectCategory(TryOnCategory category) {
    _selectedCategory = category;
    final filtered = filteredCatalog;
    if (filtered.isNotEmpty && !filtered.contains(_selectedItem)) {
      _selectedItem = filtered.first;
    }
    notifyListeners();
  }

  void selectItem(TryOnItem item) {
    _selectedItem = item;
    resetGarmentPlacement();
    notifyListeners();
  }

  void setPersonImage(String imageUri) {
    _personImage = imageUri;
    _errorMessage = null;
    notifyListeners();
  }

  void setComparisonSlider(double position) {
    _comparisonSlider = position.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setViewMode(String mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  Future<void> updateConfig({required String endpoint, required String token}) async {
    _endpointUrl = endpoint.trim();
    _apiToken = token.trim();
    await _service.saveConfig(endpoint: _endpointUrl, token: _apiToken);
    notifyListeners();
  }

  Future<void> addCustomItem(TryOnItem item) async {
    _catalog.removeWhere((i) => i.id == item.id);
    _catalog.insert(0, item);
    _selectedItem = item;
    _selectedCategory = item.category;
    await _service.saveCustomItem(item);
    notifyListeners();
  }

  Future<void> removeCustomItem(String id) async {
    _catalog.removeWhere((i) => i.id == id);
    if (_selectedItem.id == id) {
      _selectedItem = _catalog.first;
    }
    await _service.deleteCustomItem(id);
    notifyListeners();
  }

  Future<void> generateTryOn() async {
    if (_personImage == null || _personImage!.isEmpty) {
      _errorMessage = 'Please select or upload a person image first.';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _progress = 0.05;
    _progressStage = 'Initializing neural virtual try-on pipeline...';
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _service.runTryOn(
        personImageData: _personImage!,
        garmentItem: _selectedItem,
        endpointUrl: _endpointUrl.isNotEmpty ? _endpointUrl : null,
        apiToken: _apiToken.isNotEmpty ? _apiToken : null,
        onProgress: (prog, stage) {
          _progress = prog;
          _progressStage = stage;
          notifyListeners();
        },
      );

      _activeSession = session;
      _history = await _service.loadSessions();
      _isProcessing = false;
      _progress = 1.0;
      _progressStage = 'Done';
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Try-on error: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearActiveSession() {
    _activeSession = null;
    _errorMessage = null;
    _progress = 0.0;
    _progressStage = '';
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _service.clearSessions();
    _history = [];
    notifyListeners();
  }
}
