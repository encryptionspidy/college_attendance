import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'user_lookup_service.dart';

class AppState with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _error;
  int _attendanceVersion = 0; // Bumps on any attendance change
  
  // Getters
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  String? get userRole => _currentUser?['role'];
  int get attendanceVersion => _attendanceVersion;
  
  void notifyAttendanceChanged() {
    _attendanceVersion++;
    notifyListeners();
  }
  
  // Login
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _error = null;
    
    try {
      final result = await _apiService.login(username, password);
      
      if (result['success'] == true) {
        await loadCurrentUser();
        return true;
      } else {
        _error = result['error'] ?? 'Login failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Load current user
  Future<void> loadCurrentUser() async {
    try {
      _currentUser = await _apiService.getCurrentUser();
      // Initialize user lookup cache after login
      UserLookupService().getUserLookup().catchError((e) {
        print('Failed to load user lookup: $e');
        return <String, String>{}; // Return empty map on error
      });
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Logout
  void logout() {
    _apiService.clearToken();
    _currentUser = null;
    // Clear user lookup cache on logout
    UserLookupService().clearCache();
    notifyListeners();
  }
  
  // Clear user data
  void clearUser() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
