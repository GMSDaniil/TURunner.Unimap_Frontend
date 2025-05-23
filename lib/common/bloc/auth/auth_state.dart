abstract class AuthState {}

class AppInitialState extends AuthState {}

class Authenticated extends AuthState {}

class UnAuthenticated extends AuthState {}

class GuestAuthenticated extends AuthState {} // Guest Status
