import 'package:auth_app/common/bloc/button/button_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/usecase/usecase.dart';

class SignInCubit extends Cubit<ButtonState> {
  SignInCubit() : super(ButtonInitialState());

  void execute({required UseCase usecase, required dynamic params}) async {
    emit(ButtonLoadingState());
    try {
      Either result = await usecase.call(param: params);

      result.fold(
        (error) {
          emit(ButtonFailureState(errorMessage: error));
        },
        (data) {
          emit(ButtonSuccessState());
        },
      );
    } catch (e) {
      emit(ButtonFailureState(errorMessage: e.toString()));
    }
  }
}