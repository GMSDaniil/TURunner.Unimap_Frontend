class ApiUrls {
  static const baseURL = 'https://dev.cherep.co/tubify/api/';
  static const register = '${baseURL}Users/register';
  static const login = '${baseURL}Users/login';
  static const refreshToken = '${baseURL}Tokens/refreshToken';

  static const userProfile = '${baseURL}Users/getUser';

  //TODO
  static const findRoute = '${baseURL}Route/walking';
  static const findBusRoute = '${baseURL}Route/hybrid-several-points';
  static const findScooterRoute = '${baseURL}Route/scooter-route';
  static const getMensaMenu = '${baseURL}mensa/all-menus';
  static const getPointers = '${baseURL}Route/all-pointers';
  static const getWeatherInfo = '${baseURL}weather';

  // Student schedule (Moses TU Berlin)
  static const getStudentSchedule = '${baseURL}student-schedule';

  static const getStudyPrograms = '${baseURL}StudyProgram';
}
