import 'package:auth_app/common/bloc/button/button_state_cubit.dart';
import 'package:auth_app/common/bloc/button/button_state.dart';
import 'package:auth_app/presentation/home/bloc/user_display_cubit.dart';
import 'package:auth_app/presentation/home/bloc/user_display_state.dart';
import 'package:auth_app/presentation/home/pages/favourites.dart';
import 'package:auth_app/presentation/home/pages/map.dart';
import 'package:auth_app/presentation/home/pages/profile.dart';
import 'package:auth_app/presentation/home/pages/welcome.dart';
import 'package:auth_app/core/configs/theme/app_theme.dart';
import 'package:auth_app/presentation/widgets/bottom_navigation.dart'; // Import the new file
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int myIndex = 0;

  final widgetList = [
    MapPage(),
    FavouritesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => UserDisplayCubit()..displayUser()),
          BlocProvider(create: (_) => ButtonStateCubit()),
        ],
        child: BlocListener<ButtonStateCubit, ButtonState>(
          listener: (context, state) {
            if (state is ButtonSuccessState) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WelcomePage()),
              );
            }
          },
          child: widgetList[myIndex],
        ),
      ),

      // Use the new extracted bottom navigation bar
      bottomNavigationBar: AnimatedBottomNavigationBar(
        currentIndex: myIndex,
        onTap: (index) => setState(() => myIndex = index),
      ),
    );
  }
}
