class UserEntity {
  final String email;
  final String username;

  UserEntity({
    required this.email,
    required this.username
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      email: json['email'] as String,
      username: json['username'] as String,
    );
  }
}