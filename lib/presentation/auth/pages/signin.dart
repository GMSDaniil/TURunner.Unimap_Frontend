import 'package:auth_app/common/bloc/button/button_state_cubit.dart';
import 'package:auth_app/common/widgets/button/basic_app_button.dart';
import 'package:auth_app/data/models/signin_req_params.dart';
import 'package:auth_app/domain/usecases/signin.dart';
import 'package:auth_app/service_locator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/bloc/button/button_state.dart';
import '../../home/pages/home.dart';
import 'signup.dart';

class SigninPage extends StatelessWidget {
  SigninPage({super.key});

  final TextEditingController _usernameCon = TextEditingController();
  final TextEditingController _passwordCon = TextEditingController();

  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => ButtonStateCubit(),
        child: BlocListener<ButtonStateCubit, ButtonState>(
          listener: (context, state) {
            if (state is ButtonSuccessState) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
            if (state is ButtonFailureState) {
              var snackBar = SnackBar(content: Text(state.errorMessage));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          },
          child: SafeArea(
            minimum: const EdgeInsets.only(top: 100, right: 16, left: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _signin(),
                const Spacer(),
                const SizedBox(height: 50),
                _usernameField(),
                const SizedBox(height: 20),
                _passwordField(),
                const SizedBox(height: 60),
                _loginButton(context),
                const SizedBox(height: 20),
                _signupText(context),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _signin() {
    return Text(
      'Sign In',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
    );
  }

  Widget _usernameField() {
    return TextField(
      controller: _usernameCon,
      decoration: InputDecoration(
        hintText: 'Username',
        filled: true,
        fillColor: Color(0xFFF5F6FA),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        color: Colors.black, 
      ),
      onChanged: (value) {
        _validateForm();
      },
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordCon,
      obscureText: true,
      decoration: InputDecoration(
        hintText: 'Password',
        filled: true,
        fillColor: Color(0xFFF5F6FA),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        color: Colors.black, 
      ),
      onChanged: (value) {
        _validateForm();
      },
    );
  }


  void _validateForm() {
    final isUsernameValid = _usernameCon.text.isNotEmpty;
    final isPasswordValid = _passwordCon.text.isNotEmpty;
    _isFormValid.value = isUsernameValid && isPasswordValid;
  }

  Widget _loginButton(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isFormValid,
      builder: (context, isFormValid, child) {
        return BasicAppButton(
          title: 'Login',
          isEnabled: isFormValid,
          onPressed: () {
            context.read<ButtonStateCubit>().execute(
              usecase: sl<SigninUseCase>(),
              params: SigninReqParams(
                username: _usernameCon.text,
                password: _passwordCon.text,
              ),
            );
          },
        );
      },
    );
  }

  Widget _signupText(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: "Don't you have account?",
            style: TextStyle(
              color: Color(0xff3B4054),
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: ' Sign Up',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupPage()),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
