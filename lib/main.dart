import 'package:auth_app/common/bloc/auth/auth_state_cubit.dart';
import 'package:auth_app/common/providers/user.dart';
import 'package:auth_app/presentation/home/pages/home.dart';
import 'package:auth_app/presentation/home/pages/welcome.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'common/bloc/auth/auth_state.dart';
import 'core/configs/theme/app_theme.dart';
import 'presentation/auth/pages/signup.dart';
import 'presentation/auth/pages/signin.dart';
import 'service_locator.dart';
import 'package:provider/src/change_notifier_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';      // ← for TileLayer
import 'package:latlong2/latlong.dart';             // ← for LatLng & LatLngBounds
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'
    as FMTC;

import 'dart:async'; // for unawaited

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) init the default ObjectBox backend
  await FMTC.FMTCObjectBoxBackend().initialise();

  // 2) create a tile‐cache store called 'mapStore'
  await FMTC.FMTCStore('mapStore').manage.create();

  await dotenv.load(fileName: "config.env");

  // // 3) bulk–download your campus region (15–18) in the background
  // final region = FMTC.RectangleRegion(
  //   // two opposite corners of your campus bounding box
  //   LatLngBounds(
  //     LatLng(52.50, 13.31), // southWest
  //     LatLng(52.52, 13.34), // northEast
  //   ),
  // );
  // final downloadable = region.toDownloadable(
  //   minZoom: 15,
  //   maxZoom: 18,
  //   options: TileLayer(
  //     urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  //     userAgentPackageName: 'com.example.app',
  //   ),
  // );
  // // fire‐and‐forget the bulk download (streams ignored)
  // FMTC.FMTCStore('mapStore').download.startForeground(
  //   region: downloadable,
  // );

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

    return MultiBlocProvider(
      // BlocProvider provides AuthStateCubit to the whole widget tree
      providers: [
        BlocProvider(create: (context) => AuthStateCubit()..appStarted()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
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
