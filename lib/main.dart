import 'package:auth_app/common/bloc/auth/auth_state_cubit.dart';
import 'package:auth_app/presentation/home/pages/home.dart';
import 'package:auth_app/presentation/home/pages/welcome.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'common/bloc/auth/auth_state.dart';
import 'core/configs/theme/app_theme.dart';
import 'presentation/auth/pages/signup.dart';
import 'presentation/auth/pages/signin.dart';
import 'service_locator.dart';

import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
    ),
  );
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );

    return BlocProvider(
      // BlocProvider provides AuthStateCubit to the whole widget tree
      create: (context) => AuthStateCubit()..appStarted(),
      child: MaterialApp(
        theme: AppTheme.appTheme,
        debugShowCheckedModeBanner: false,
        home: BlocBuilder<AuthStateCubit, AuthState>(
          builder: (context, state) {
            if (state is Authenticated || state is GuestAuthenticated) {
              return const HomePage(); // Show MapPage for both Authenticated and Guest users
            }
            if (state is UnAuthenticated) {
              return const WelcomePage();
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        routes: {
          '/signup': (_) => SignupPage(),
          '/signin': (_) => SigninPage(),
          '/home': (_) => const HomePage(), // Add this route for HomePage
        },
      ),
    );
  }
}
