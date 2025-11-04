import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  String? _token;
  
  static const String _defaultBaseUrl = 'http://localhost:8000';
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status! < 500,
    ));
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      error: kDebugMode,
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('API Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }
  
  void setToken(String token) {
    _token = token;
  }
  
  void clearToken() {
    _token = null;
  }
  
  // Authentication
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/token',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          contentType: 'application/json',
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        setToken(token);
        return {'success': true, 'token': token, 'role': response.data['role']};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Incorrect username or password'};
      } else if (response.statusCode == 422) {
        return {'success': false, 'error': 'Invalid request format'};
      } else {
        return {'success': false, 'error': response.data['detail'] ?? 'Login failed'};
      }
    } on DioException catch (e) {
      debugPrint('Login error: ${e.message}');
      if (e.response != null) {
        return {'success': false, 'error': e.response?.data['detail'] ?? 'Server error'};
      }
      return {'success': false, 'error': 'Network error: ${e.message}'};
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  /// Get student home data (user info + attendance stats)
  Future<Map<String, dynamic>> getStudentHomeData() async {
    try {
      // Fetch user data and attendance stats in parallel
      final userFuture = getCurrentUser();
      final statsFuture = getAttendancePercentage();

      final results = await Future.wait([userFuture, statsFuture]);

      return {
        'user': results[0],
        'stats': results[1],
      };
    } catch (e) {
      debugPrint('Get student home data error: $e');
      return {
        'user': null,
        'stats': {'percentage': 0.0, 'present_days': 0, 'total_days': 0},
      };
    }
  }

  // Leave Requests
  Future<List<dynamic>> getMyLeaveRequests() async {
    try {
      final response = await _dio.get('/requests/me');
      if (response.statusCode == 200) {
        return response.data as List;
      }
      return [];
    } catch (e) {
      debugPrint('Get my leave requests error: $e');
      return [];
    }
  }
  
  Future<List<dynamic>> getPendingRequests() async {
    try {
      final response = await _dio.get('/requests/pending');
      if (response.statusCode == 200) {
        return response.data as List;
      }
      return [];
    } catch (e) {
      debugPrint('Get pending requests error: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> createLeaveRequest({
    required String startDate,
    required String endDate,
    required String reason,
    String? imageData,
    List<String>? advisorIds,
  }) async {
    try {
      final response = await _dio.post('/requests/', data: {
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
        if (imageData != null) 'image_data': imageData,
        if (advisorIds != null && advisorIds.isNotEmpty) 'advisor_ids': advisorIds,
      });
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to create request'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<dynamic>> getAdvisors() async {
    try {
      final response = await _dio.get('/users/advisors');
      if (response.statusCode == 200) {
        return response.data as List;
      }
      return [];
    } catch (e) {
      debugPrint('Get advisors error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> approveRequest(String requestId) async {
    try {
      final response = await _dio.post('/requests/$requestId/approve');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to approve request'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Map<String, dynamic>> rejectRequest(String requestId) async {
    try {
      final response = await _dio.post('/requests/$requestId/reject');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to reject request'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Attendance
  Future<List<dynamic>> getMyAttendance() async {
    try {
      final response = await _dio.get('/attendance/me');
      if (response.statusCode == 200) {
        return response.data as List;
      }
      return [];
    } catch (e) {
      debugPrint('Get my attendance error: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> getAttendancePercentage() async {
    try {
      final response = await _dio.get('/attendance/me/percentage');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return {'percentage': 0.0, 'present_days': 0, 'total_days': 0};
    } catch (e) {
      debugPrint('Get attendance percentage error: $e');
      return {'percentage': 0.0, 'present_days': 0, 'total_days': 0};
    }
  }
  
  Future<List<dynamic>> getStudentsForAttendance({
    required String date,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get('/attendance/roster', queryParameters: {
        'date': date,
      });
      if (response.statusCode == 200) {
        return response.data as List;
      }
      return [];
    } catch (e) {
      debugPrint('Get students for attendance error: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> markAttendance({
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final response = await _dio.post('/attendance/mark', data: {
        'records': records,
      });
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to mark attendance'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Map<String, dynamic>> markHoliday({
    required String date,
    String? description,
  }) async {
    try {
      final response = await _dio.post('/attendance/set-day-status', data: {
        'date': date,
        'status': 'Holiday',
        if (description != null) 'description': description,
      });
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to mark holiday'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Users
  Future<List<dynamic>> getAllUsers({int page = 1, int limit = 50}) async {
    try {
      final response = await _dio.get('/users/', queryParameters: {
        'page': page,
        'limit': limit,
      });
      if (response.statusCode == 200) {
        return response.data as List;
      }
      return [];
    } catch (e) {
      debugPrint('Get all users error: $e');
      return [];
    }
  }
  
  Future<List<dynamic>> getStudents({int page = 1, int limit = 50}) async {
    try {
      final response = await _dio.get('/users/students', queryParameters: {
        'page': page,
        'limit': limit,
      });
      if (response.statusCode == 200) {
        return response.data as List;
      }
      return [];
    } catch (e) {
      debugPrint('Get students error: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/$userId', data: data);
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to update user'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final response = await _dio.delete('/users/$userId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Failed to delete user'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _dio.put('/users/me/profile', data: profileData);
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to update profile'};
    } catch (e) {
      debugPrint('Update profile error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadProfilePicture(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      
      final response = await _dio.post('/users/me/upload-profile-picture', data: formData);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to upload picture'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Admin - Create User
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/users/', data: userData);
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to create user'};
    } catch (e) {
      debugPrint('Create user error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Admin - Get all attendance records
  Future<List<dynamic>> getAllAttendanceRecords({
    String? date,
    String? studentId,
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (date != null) queryParams['date'] = date;
      if (studentId != null) queryParams['student_id'] = studentId;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get('/attendance/', queryParameters: queryParams);
      if (response.statusCode == 200) {
        return response.data as List;
      }
      return [];
    } catch (e) {
      debugPrint('Get all attendance records error: $e');
      return [];
    }
  }

  // Admin - Get all requests (not just pending)
  Future<List<dynamic>> getAllRequests({
    String? status,
    String? studentId,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) queryParams['status'] = status;
      if (studentId != null) queryParams['student_id'] = studentId;

      final response = await _dio.get('/requests/', queryParameters: queryParams);
      if (response.statusCode == 200) {
        return response.data as List;
      }
      return [];
    } catch (e) {
      debugPrint('Get all requests error: $e');
      return [];
    }
  }

  // Get user lookup map (ID -> Name)
  Future<Map<String, String>> getUserLookup() async {
    try {
      final response = await _dio.get('/users/lookup');
      if (response.statusCode == 200) {
        // Convert dynamic values to String
        final data = response.data as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, value.toString()));
      }
      return {};
    } catch (e) {
      debugPrint('Get user lookup error: $e');
      return {};
    }
  }

  // Get request history (processed requests)
  Future<List<dynamic>> getRequestHistory() async {
    try {
      final response = await _dio.get('/requests/history');
      if (response.statusCode == 200) {
        return response.data as List;
      }
      return [];
    } catch (e) {
      debugPrint('Get request history error: $e');
      return [];
    }
  }

  // Get request image URL
  String getRequestImageUrl(String requestId) {
    return '${_dio.options.baseUrl}/requests/$requestId/image';
  }
}
