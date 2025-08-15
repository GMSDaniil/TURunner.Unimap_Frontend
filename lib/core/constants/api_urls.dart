import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiUrls {
  static String get baseURL => dotenv.env['BASE_URL']!;

  static String get register => '${baseURL}Users/register';
  static String get login => '${baseURL}Users/login';
  static String get refreshToken => '${baseURL}Tokens/refreshToken';

  static String get userProfile => '${baseURL}Users/getUser';

  //TODO
  static String get findRoute => '${baseURL}Route/walking';
  static String get findBusRoute => '${baseURL}Route/hybrid-several-points';
  static String get findScooterRoute => '${baseURL}Route/scooter-route';
  static String get getMensaMenu => '${baseURL}mensa/all-menus';
  static String get getPointers => '${baseURL}Route/all-pointers';
  static String get getWeatherInfo => '${baseURL}weather';

  // Student schedule (Moses TU Berlin)
  static String get getStudentSchedule => '${baseURL}student-schedule';
  static String get getRoomSchedule => '${baseURL}room_schedule';

  static String get getStudyPrograms => '${baseURL}StudyProgram';

  static String get addFavouriteMeal => '${baseURL}Users/addFavouriteMeal';
  static String get removeFavouriteMeal =>
      '${baseURL}Users/removeFavouriteMeal';
}
