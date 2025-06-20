class DeleteFavouriteReqParams {
  final String userId;
  final String pointerId;

  DeleteFavouriteReqParams({required this.userId, required this.pointerId});

  Map<String, dynamic> toJson() => {'userId': userId, 'pointerId': pointerId};
}
