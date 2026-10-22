import 'package:dio/dio.dart';

class ErrorHandler {
  static String getMessage(dynamic e) {
    if (e is DioException) {
      if (e.response != null && e.response!.data is Map) {
        final data = e.response!.data as Map;
        // Backend returns {"error": "..."}
        if (data.containsKey('error')) {
          return data['error'].toString();
        }
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
      }
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Please check your internet.";
        case DioExceptionType.connectionError:
          return "Cannot connect to server. Is the backend running?";
        default:
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            return "Unauthorized. Please check your credentials.";
          }
          return "Server error: ${e.response?.statusCode ?? 'Unknown'}";
      }
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}
