import 'package:auth_app/common/widgets/button/basic_app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/bloc/button/button_state_cubit.dart';

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
                  'assets/images/logo__.png',
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
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false
                      );
                    },
                    child: Container(
                      width: screenWidth,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.9),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                        ]),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.7),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 5),
                            blurRadius: 15,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            offset: const Offset(0, -1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
