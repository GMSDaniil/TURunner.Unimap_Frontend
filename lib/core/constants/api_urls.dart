import 'package:auth_app/domain/usecases/get_mensa_menu.dart';

class ApiUrls {
  static const baseURL = 'http://188.245.63.53:5000/';
  static const baseRouteURL = 'http://188.245.63.53:5500/';
  static const register = '${baseURL}api/Users/register';
  static const login = '${baseURL}api/Users/login';
  static const refreshToken = '${baseURL}api/Tokens/refreshToken';

  static const userProfile = '${baseURL}api/Users/getUser';

  //TODO
  static const findRoute = '${baseRouteURL}api/Route/walking';
  static const getMensaMenu = '${baseURL}api/Mensa/getMensaMenu';
  static const getPointers = '${baseRouteURL}api/Pointers/getPointers';
}
