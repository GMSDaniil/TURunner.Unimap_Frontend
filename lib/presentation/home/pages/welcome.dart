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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 60),

            // ─── Logo ──────────────────────────────────────────────────────
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Image.asset(
                  'assets/images/logo.jpg', // Make sure this path and name match
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ─── Buttons ───────────────────────────────────────────────────
            BlocProvider(
              create: (_) => ButtonStateCubit(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
                child: Column(
                  children: [
                    BasicAppButton(
                      title: 'Create Account',
                      onPressed: () {
                        Navigator.of(context).pushNamed('/signup');
                      },
                      width: screenWidth,
                      isEnabled: true,
                    ),
                    const SizedBox(height: 18),
                    BasicAppButton(
                      title: 'Sign In',
                      onPressed: () {
                        Navigator.of(context).pushNamed('/signin');
                      },
                      width: screenWidth,
                      isEnabled: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
