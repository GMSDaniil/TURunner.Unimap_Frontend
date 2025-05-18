import 'package:auth_app/common/bloc/button/button_state_cubit.dart';
import 'package:auth_app/common/widgets/button/basic_app_button.dart';
import 'package:auth_app/core/configs/theme/app_theme.dart';
import 'package:auth_app/domain/entities/user.dart';
import 'package:auth_app/domain/usecases/logout.dart';
import 'package:auth_app/presentation/home/bloc/user_display_cubit.dart';
import 'package:auth_app/presentation/home/bloc/user_display_state.dart';
import 'package:auth_app/presentation/home/pages/map.dart';
import 'package:auth_app/presentation/home/pages/profile.dart';
import 'package:auth_app/presentation/home/pages/welcome.dart';
import 'package:auth_app/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth_app/presentation/home/pages/favourites.dart';


import '../../../common/bloc/button/button_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int myIndex = 0;

  List<Widget> widgetList = const [
    MapPage(),
    FavouritesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //  title: const Text('Bottom Navigation Bar'),
      // ),
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
                MaterialPageRoute(builder: (context) => const WelcomePage()),
              );
            }
          },
          child: widgetList[myIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).primaryGradient, // Uses extension method below
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    myIndex = 0;
                  });
                },
                icon: Icon(
                  Icons.map,
                  color: myIndex == 0 ? Colors.amber : Colors.white,
                ),
                tooltip: 'Map',
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    myIndex = 1;
                  });
                },
                icon: Icon(
                  Icons.favorite,
                  color: myIndex == 1 ? Colors.amber : Colors.white,
                ),
                tooltip: 'Favorites',
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    myIndex = 2;
                  });
                },
                icon: Icon(
                  Icons.person,
                  color: myIndex == 2 ? Colors.amber : Colors.white,
                ),
                tooltip: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}