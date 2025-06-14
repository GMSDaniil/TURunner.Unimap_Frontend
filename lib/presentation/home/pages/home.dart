import 'package:auth_app/common/bloc/button/button_state_cubit.dart';
import 'package:auth_app/common/bloc/button/button_state.dart';
import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/presentation/home/bloc/user_display_cubit.dart';
import 'package:auth_app/presentation/home/bloc/user_display_state.dart';
import 'package:auth_app/presentation/home/pages/favourites.dart';
import 'package:auth_app/presentation/home/pages/map.dart';
import 'package:auth_app/presentation/home/pages/profile.dart';
import 'package:auth_app/presentation/home/pages/welcome.dart';
import 'package:auth_app/core/configs/theme/app_theme.dart';
import 'package:auth_app/presentation/widgets/bottom_navigation.dart'; // Import the new file
import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int myIndex = 0;

  @override
  Widget build(BuildContext context) {
    final widgetList = [
      MapPage(scaffoldKeyForBottomSheet: _scaffoldKey),
      FavouritesPage(),
      ProfilePage(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: Scaffold(
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
        bottomNavigationBar: AnimatedBottomNavigationBar(
          currentIndex: myIndex,
          onTap: (index) => setState(() => myIndex = index),
        ),
      ),
    );
  }

  void showRouteOptionsSheet({
    required ValueNotifier<Map<TravelMode, RouteData>> routesNotifier,
    required TravelMode currentMode,
    required ValueChanged<TravelMode> onModeChanged,
    required VoidCallback onClose,
  }) {
    _scaffoldKey.currentState?.showBottomSheet(
      (ctx) => RouteOptionsSheet(
        routesNotifier: routesNotifier,
        currentMode: currentMode,
        onClose: onClose,
        onModeChanged: onModeChanged,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}
