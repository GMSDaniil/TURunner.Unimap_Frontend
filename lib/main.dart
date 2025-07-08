import 'package:auth_app/common/bloc/auth/auth_state_cubit.dart';
import 'package:auth_app/common/providers/theme.dart';
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
// import 'package:provider/src/change_notifier_provider.dart';
import 'package:provider/provider.dart';

import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
//import 'package:flutter_map/flutter_map.dart';      // ← for TileLayer
import 'package:latlong2/latlong.dart'; // ← for LatLng & LatLngBounds
//import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart' as FMTC;

import 'dart:async'; // for unawaited

import 'package:auth_app/data/models/add_favourite_req_params.dart';
import 'package:auth_app/data/models/delete_favourite_req_params.dart';
import 'package:auth_app/domain/repository/favourites.dart';
import 'package:auth_app/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "config.env");
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN']!);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // --- Mapbox Offline Caching using TileStore/OfflineManager ---
  // This will prefetch the style and tiles for the campus region for offline use.
  // Requires mapbox_maps_flutter >= 0.4.0 and native SDK support.
  try {
    final offlineManager = await OfflineManager.create();
    final tileStore = await TileStore.createDefault();
    // Optionally reset disk quota to default (null = default)
    tileStore.setDiskQuota(null);

    // Download style pack (adjust style as needed)
    final styleUri = MapboxStyles.MAPBOX_STREETS;
    final stylePackLoadOptions = StylePackLoadOptions(
      glyphsRasterizationMode:
          GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
      metadata: {"tag": "campus"},
      acceptExpired: false,
    );
    await offlineManager.loadStylePack(styleUri, stylePackLoadOptions, (
      progress,
    ) {
      // Optionally handle progress
    });

    // Download tile region for campus (adjust coordinates/zoom as needed)
    final tileRegionId = "campus-tile-region";
    final tileRegionLoadOptions = TileRegionLoadOptions(
      geometry: {
        "type": "Polygon",
        "coordinates": [
          [
            [13.31, 52.50], // SW
            [13.34, 52.50], // SE
            [13.34, 52.52], // NE
            [13.31, 52.52], // NW
            [13.31, 52.50], // Close polygon
          ],
        ],
      },
      descriptorsOptions: [
        TilesetDescriptorOptions(styleURI: styleUri, minZoom: 15, maxZoom: 18),
      ],
      acceptExpired: true,
      networkRestriction: NetworkRestriction.NONE,
    );
    await tileStore.loadTileRegion(tileRegionId, tileRegionLoadOptions, (
      progress,
    ) {
      // Optionally handle progress
    });
  } catch (e) {
    debugPrint('Mapbox offline caching error: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.bottom],
  );

  setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // BlocProvider provides AuthStateCubit to the whole widget tree
      providers: [
        BlocProvider(create: (context) => AuthStateCubit()..appStarted()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child){
        return MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
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
        );
      }
      ),
    );
  }
}
