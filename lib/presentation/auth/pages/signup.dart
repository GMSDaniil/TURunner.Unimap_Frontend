import 'package:auth_app/common/bloc/auth/sign_in_cubit.dart';
import 'package:auth_app/common/bloc/button/button_state.dart';
import 'package:auth_app/common/bloc/button/button_state_cubit.dart';
import 'package:auth_app/common/providers/user.dart';
import 'package:auth_app/common/widgets/button/basic_app_button.dart';
import 'package:auth_app/data/models/signin_req_params.dart';
import 'package:auth_app/data/models/signin_response.dart';
import 'package:auth_app/data/models/signup_req_params.dart';
import 'package:auth_app/domain/usecases/signin.dart';
import 'package:auth_app/domain/usecases/signup.dart';
import 'package:auth_app/presentation/auth/pages/signin.dart';
import 'package:auth_app/presentation/home/pages/home.dart';
import 'package:auth_app/service_locator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class SignupPage extends StatelessWidget {
  SignupPage({super.key});

  final TextEditingController _usernameCon = TextEditingController();
  final TextEditingController _emailCon = TextEditingController();
  final TextEditingController _passwordCon = TextEditingController();

  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);

  final ValueNotifier<String?> _emailError = ValueNotifier(null);
  final RegExp _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  final ValueNotifier<String?> _passwordError = ValueNotifier(null);

  final ValueNotifier<bool> _hasUppercase = ValueNotifier(false);
  final ValueNotifier<bool> _hasLowercase = ValueNotifier(false);
  final ValueNotifier<bool> _hasNumber = ValueNotifier(false);
  final ValueNotifier<bool> _hasSpecialChar = ValueNotifier(false);
  final ValueNotifier<bool> _hasMinLength = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ButtonStateCubit()), // For SignUp
        ],
          child: BlocListener<ButtonStateCubit, ButtonState>(
            listener: (context, state) {
              if (state is ButtonSuccessState) {
                SignInResponse response = state.data;
                var userProvider = Provider.of<UserProvider>(context, listen: false);
                userProvider.setUser(response.user);
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
              child: SafeArea(


                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _signup(),
                      const Spacer(),
                      const SizedBox(height: 50),
                      _userNameField(context),
                      const SizedBox(height: 20),
                      _emailField(context),
                      const SizedBox(height: 20),
                      _passwordField(context),
                      const SizedBox(height: 60),
                      _createAccountButton(context),
                      const SizedBox(height: 20),
                      _signinText(context),
                      const SizedBox(height: 18),
                    ],
                  ),
              ),
            ),
          ),
        ),
      );
    
  }

  Widget _signup() {
    return const Text(
      'Sign Up',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
    );
  }

  Widget _userNameField(BuildContext context) {
    return TextField(
      controller: _usernameCon,
      decoration: InputDecoration(
        hintText: 'Username',
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        
      ),
      // style: const TextStyle(
      //   color: Colors.black, 
      // ),
    );
  }

  Widget _emailField(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _emailError,
      builder: (context, error, child) {
        return TextField(
          controller: _emailCon,
          decoration: InputDecoration(
            hintText: 'Email',
            errorText: error,
            filled: true,
            fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          // style: const TextStyle(
          //   color: Colors.black, 
          // ),
          onChanged: (value) {
            if (!_emailRegex.hasMatch(value)) {
              _emailError.value = 'Invalid email format';
            } else {
              _emailError.value = null;
            }
            _validateForm();
          },
        );
      },
    );
  }

  void _validateForm() {
    final isEmailValid = _emailError.value == null && _emailCon.text.isNotEmpty;
    final isPasswordValid =
        _passwordError.value == null && _passwordCon.text.isNotEmpty;
    _isFormValid.value = isEmailValid && isPasswordValid;
  }

  Widget _passwordField(BuildContext context) {
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
                errorText: error,
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              // style: const TextStyle(
              //   color: Colors.black, 
              // ),
              onChanged: (value) {
                _hasUppercase.value =
                    PasswordRules.requireUppercase
                        ? value.contains(RegExp(r'[A-Z]'))
                        : true;
                _hasLowercase.value =
                    PasswordRules.requireLowercase
                        ? value.contains(RegExp(r'[a-z]'))
                        : true;
                _hasNumber.value =
                    PasswordRules.requireNumber
                        ? value.contains(RegExp(r'\d'))
                        : true;
                _hasSpecialChar.value =
                    PasswordRules.requireSpecialChar
                        ? value.contains(PasswordRules.specialCharRegex)
                        : true;
                _hasMinLength.value = value.length >= PasswordRules.minLength;

                if (_hasUppercase.value &&
                    _hasLowercase.value &&
                    _hasNumber.value &&
                    _hasSpecialChar.value &&
                    _hasMinLength.value) {
                  _passwordError.value = null;
                } else {
                  _passwordError.value = 'Password must meet all requirements.';
                }
                _validateForm();
              },
            ),
            const SizedBox(height: 10),
            _passwordError.value == null && _passwordCon.text.isNotEmpty
                ? Container()
                : _passwordRequirements(),
          ],
        );
      },
    );
  }

  Widget _createAccountButton(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isFormValid,
      builder: (context, isFormValid, child) {
        return BasicAppButton(
          title: 'Create Account',
          isEnabled: isFormValid,
          onPressed: () {
            context.read<ButtonStateCubit>().execute(
              usecase: sl<SignupUseCase>(),
              params: SignupReqParams(
                email: _emailCon.text,
                password: _passwordCon.text,
                username: _usernameCon.text,
              ),
            );
          },
        );
      },
    );
  }

  Widget _signinText(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Do you have account?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: ' Sign In',
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
                      MaterialPageRoute(builder: (context) => SigninPage()),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _passwordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requirementItem(
          'At least ${PasswordRules.minLength} characters',
          _hasMinLength,
        ),

        _requirementItem('At least one uppercase letter', _hasUppercase),

        _requirementItem('At least one lowercase letter', _hasLowercase),

        _requirementItem('At least one number', _hasNumber),

        _requirementItem('At least one special character', _hasSpecialChar),
      ],
    );
  }

  Widget _requirementItem(String text, ValueNotifier<bool> notifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isValid, child) {
        return Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.cancel,
              color: isValid ? Theme.of(context).colorScheme.primary : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                // color: isValid ? Colors.green : Colors.grey,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}

class PasswordRules {
  static const int minLength = 12;
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireNumber = true;
  static const bool requireSpecialChar = true;

  static final RegExp specialCharRegex = RegExp(
    r'''[/$\\&+,:;=?@#|<>.^*()%!'{}\_"[\]~`-]''',
  );
}
