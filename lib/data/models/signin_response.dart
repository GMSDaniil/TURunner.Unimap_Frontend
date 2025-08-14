import 'package:auth_app/domain/entities/user.dart';

class SignInResponse{
  final String accessToken;
  final String refreshToken;
  final UserEntity user;

  SignInResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user
  });

  factory SignInResponse.fromJson(Map<String, dynamic> json) {

    return SignInResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserEntity.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

