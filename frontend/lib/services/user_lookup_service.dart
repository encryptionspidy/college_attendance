import 'api_service.dart';

/// Service to manage user ID to name lookups
/// Caches the mapping for efficient name resolution across the app
class UserLookupService {
  static final UserLookupService _instance = UserLookupService._internal();
  factory UserLookupService() => _instance;
  UserLookupService._internal();

  final ApiService _apiService = ApiService();

  // Cache for user ID to name mapping
  Map<String, String> _userLookup = {};
  bool _isInitialized = false;
  DateTime? _lastFetchTime;
  static const _cacheValidityDuration = Duration(minutes: 30);

  /// Get the user lookup map (fetches if not cached or expired)
  Future<Map<String, String>> getUserLookup({bool forceRefresh = false}) async {
    // Check if cache is valid
    if (!forceRefresh && _isInitialized && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheValidityDuration) {
        return _userLookup;
      }
    }

    // Fetch fresh data
    await _fetchUserLookup();
    return _userLookup;
  }

  /// Fetch user lookup from backend
  Future<void> _fetchUserLookup() async {
    try {
      final response = await _apiService.getUserLookup();

      if (response is Map) {
        _userLookup = Map<String, String>.from(response);
        _isInitialized = true;
        _lastFetchTime = DateTime.now();
        print('UserLookupService: Loaded ${_userLookup.length} user mappings');
      }
    } catch (e) {
      print('UserLookupService: Error fetching user lookup: $e');
    }
  }

  /// Get user name by ID
  /// Returns the name if found, otherwise returns the ID or fallback text
  String getUserName(String? userId, {String fallback = 'Unknown'}) {
    if (userId == null || userId.isEmpty) {
      return fallback;
    }
    return _userLookup[userId] ?? userId;
  }

  /// Get multiple user names by IDs
  List<String> getUserNames(List<String>? userIds) {
    if (userIds == null || userIds.isEmpty) {
      return [];
    }
    return userIds.map((id) => getUserName(id)).toList();
  }

  /// Check if a user name is available for a given ID
  bool hasUserName(String? userId) {
    if (userId == null || userId.isEmpty) {
      return false;
    }
    return _userLookup.containsKey(userId);
  }

  /// Clear the cache (useful for logout or when user data changes)
  void clearCache() {
    _userLookup.clear();
    _isInitialized = false;
    _lastFetchTime = null;
  }

  /// Refresh the lookup cache
  Future<void> refresh() async {
    await getUserLookup(forceRefresh: true);
  }

  /// Get the number of cached user mappings
  int get cacheSize => _userLookup.length;

  /// Check if cache is initialized
  bool get isInitialized => _isInitialized;

  /// Get cache age in minutes
  int? get cacheAgeMinutes {
    if (_lastFetchTime == null) return null;
    return DateTime.now().difference(_lastFetchTime!).inMinutes;
  }
}

