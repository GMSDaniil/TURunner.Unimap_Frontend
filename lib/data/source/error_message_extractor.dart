class ErrorMessageExtractor {
  String extractErrorMessage(dynamic data) {
    if (data is Map && data.containsKey('message')) {
      return data['message'].toString();
    } else if (data is String) {
      return data;
    }
    return 'An error occurred';
  }
}