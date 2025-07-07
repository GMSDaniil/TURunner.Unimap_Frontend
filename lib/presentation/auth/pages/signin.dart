import 'package:auth_app/common/bloc/button/button_state_cubit.dart';
import 'package:auth_app/common/providers/user.dart';
import 'package:auth_app/common/widgets/button/basic_app_button.dart';
import 'package:auth_app/data/models/signin_req_params.dart';
import 'package:auth_app/data/models/signin_response.dart';
import 'package:auth_app/domain/usecases/signin.dart';
import 'package:auth_app/service_locator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../common/bloc/button/button_state.dart';
import '../../home/pages/home.dart';
import 'signup.dart';

import 'package:auth_app/domain/repository/favourites.dart';
import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/domain/usecases/get_favourites.dart';

class SigninPage extends StatelessWidget {
  SigninPage({super.key});

  final TextEditingController _usernameCon = TextEditingController();
  final TextEditingController _passwordCon = TextEditingController();

  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);
  final ValueNotifier<String?> _usernameError = ValueNotifier(null);
  final ValueNotifier<String?> _passwordError = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => ButtonStateCubit(),
        child: BlocListener<ButtonStateCubit, ButtonState>(
          listener: (context, state) async {
            if (state is ButtonSuccessState) {
              _usernameError.value = null;
              _passwordError.value = null;
              SignInResponse response = state.data;
              var userProvider = Provider.of<UserProvider>(
                context,
                listen: false,
              );
              userProvider.setUser(response.user);

              print('hello world');

              /// loding favourites after login
              final favouritesResult = await sl<GetFavouritesUseCase>().call();
              print('DEBUG favouritesResult: $favouritesResult');

              favouritesResult.fold(
                (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to load favourites: $error'),
                    ),
                  );
                  userProvider.setFavourites([]);
                },
                (favourites) {
                  userProvider.setFavourites(favourites);
                },
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
            if (state is ButtonFailureState) {
              // Show error message on login failure
              _handleLoginError(state.errorMessage);
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

  void _handleLoginError(String errorMessage) {
    // Clear previous errors
    _usernameError.value = null;
    _passwordError.value = null;

    // Parse error message and set appropriate field errors
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('user') || lowerError.contains('user not found')) {
      _usernameError.value = 'Username not found';
    } else if (lowerError.contains('password') ||
        lowerError.contains('incorrect password')) {
      _passwordError.value = 'Incorrect password';
    } else if (lowerError.contains('invalid credentials') ||
        lowerError.contains('login failed')) {
      // Generic error - show on both fields
      _usernameError.value = 'Invalid credentials';
      _passwordError.value = 'Invalid credentials';
    } else {
      // Unknown error - show on username field as fallback
      _usernameError.value = errorMessage;
    }
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
    return ValueListenableBuilder<String?>(
      valueListenable: _usernameError,
      builder: (context, error, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _usernameCon,
              decoration: InputDecoration(
                hintText: 'Username',
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                // Add error border if there's an error
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: error != null
                      ? const BorderSide(color: Colors.red, width: 1.0)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: error != null
                      ? const BorderSide(color: Colors.red, width: 2.0)
                      : const BorderSide(color: Color(0xFF7B61FF), width: 2.0),
                ),
              ),
              style: const TextStyle(color: Colors.black),
              onChanged: (value) {
                // Clear error when user starts typing
                if (error != null) {
                  _usernameError.value = null;
                }
                _validateForm();
              },
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _passwordField() {
    return ValueListenableBuilder<String?>(
      valueListenable: _passwordError,
      builder: (context, error, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _passwordCon,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                // Add error border if there's an error
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: error != null
                      ? const BorderSide(color: Colors.red, width: 1.0)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: error != null
                      ? const BorderSide(color: Colors.red, width: 2.0)
                      : const BorderSide(color: Color(0xFF7B61FF), width: 2.0),
                ),
              ),
              style: const TextStyle(color: Colors.black),
              onChanged: (value) {
                // Clear error when user starts typing
                if (error != null) {
                  _passwordError.value = null;
                }
                _validateForm();
              },
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        );
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
            recognizer: TapGestureRecognizer()
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
