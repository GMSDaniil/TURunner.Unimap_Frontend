import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalService {
  Future<bool> isLoggedIn();
  Future<Either> logout();
} 


class AuthLocalServiceImpl extends AuthLocalService {


  @override
  Future<bool> isLoggedIn() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var token = sharedPreferences.getString('accessToken');
    if (token  == null ){
      return false;
    } else {
      return true;
    }
  }
  
  @override
  Future<Either> logout() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    // Only remove authentication-related keys instead of clearing all.
    // This preserves persistent user-neutral app settings (e.g. map theme).
    const authKeys = [
      'accessToken',
      'refreshToken',
      // Add any other strictly auth-related keys here if introduced later
    ];
    for (final k in authKeys) {
      await sharedPreferences.remove(k);
    }
    return const Right(true);
  }
  
}
