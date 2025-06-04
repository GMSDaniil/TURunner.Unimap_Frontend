import 'package:auth_app/domain/usecases/get_mensa_menu.dart';

class ApiUrls {
  static const baseURL = 'https://dev.cherep.co/tubify/api/';
  static const register = '${baseURL}Users/register';
  static const login = '${baseURL}Users/login';
  static const refreshToken = '${baseURL}Tokens/refreshToken';

  static const userProfile = '${baseURL}Users/getUser';

  //TODO
  static const findRoute = '${baseURL}Route/walking';
  static const getMensaMenu = '${baseURL}Mensa/getMensaMenu';
  static const getPointers = '${baseURL}Pointers/getPointers';
}
