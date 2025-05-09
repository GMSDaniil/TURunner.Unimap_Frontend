import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  Future<bool> refreshToken() async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var refreshToken = sharedPreferences.getString('refreshToken');

      var response = await sl<DioClient>().post(
        ApiUrls.refreshToken,
        data: {
          'refreshToken': refreshToken,
        },
      );

      var newAccessToken = response.data['accessToken'];
      var newRefreshToken = response.data['refreshToken'];

      await sharedPreferences.setString('accessToken', newAccessToken);
      await sharedPreferences.setString('refreshToken', newRefreshToken);

      return true;
    } catch (e) {
      return false;
    }
  }
}