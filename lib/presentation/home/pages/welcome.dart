import 'package:auth_app/common/widgets/button/basic_app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/bloc/button/button_state_cubit.dart';
import '../../../common/bloc/auth/auth_state_cubit.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 100),

            // App logo
            Center(
              child: SizedBox(
                width: 340,
                height: 340,
                child: Image.asset(
                  'assets/images/logo__.jpeg',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 100),

            // Button section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  BlocProvider(
                    create: (_) => ButtonStateCubit(),
                    child: Column(
                      children: [
                        // Create Account Button
                        BasicAppButton(
                          title: 'Create Account',
                          onPressed: () {
                            Navigator.of(context).pushNamed('/signup');
                          },
                          width: screenWidth,
                          isEnabled: true,
                        ),
                        const SizedBox(height: 18),

                        // Sign In Button
                        BasicAppButton(
                          title: 'Sign In',
                          onPressed: () {
                            Navigator.of(context).pushNamed('/signin');
                          },
                          width: screenWidth,
                          isEnabled: true,
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),

                  // Guest Access Button
                  SizedBox(
                    width: screenWidth,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.grey[200],
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        context.read<AuthStateCubit>().loginAsGuest();
                      },
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
