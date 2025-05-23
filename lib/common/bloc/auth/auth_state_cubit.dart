import 'package:auth_app/common/bloc/auth/auth_state.dart';
import 'package:auth_app/domain/usecases/is_logged_in.dart';
import 'package:auth_app/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthStateCubit extends Cubit<AuthState> {
  AuthStateCubit() : super(AppInitialState());

  void appStarted() async {
    var isLoggedIn = await sl<IsLoggedInUseCase>().call();
    if (isLoggedIn) {
      emit(Authenticated());
    } else {
      emit(UnAuthenticated());
    }
  }

  void loginAsGuest() {
    emit(GuestAuthenticated());
  }

  void logout() {
    emit(UnAuthenticated());
  }
}
