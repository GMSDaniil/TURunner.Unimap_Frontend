class FavouriteStatusResponse {
  final bool success;
  final String message;

  FavouriteStatusResponse({required this.success, required this.message});

  factory FavouriteStatusResponse.fromJson(Map<String, dynamic> json) {
    return FavouriteStatusResponse(
      success: json['success'] == true,
      message: json['message'] ?? '',
    );
  }
}
