import 'package:auth_app/common/bloc/button/button_state_cubit.dart';
import 'package:auth_app/common/bloc/button/button_state.dart';
import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/presentation/home/bloc/user_display_cubit.dart';
import 'package:auth_app/presentation/home/bloc/user_display_state.dart';
import 'package:auth_app/presentation/home/pages/favourites.dart';
import 'package:auth_app/presentation/home/pages/map.dart';
import 'package:auth_app/presentation/home/pages/profile.dart';
import 'package:auth_app/presentation/home/pages/welcome.dart';
import 'package:auth_app/presentation/widgets/bottom_navigation.dart';
import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _tabIndex = 0;
  bool _hideNav = false;

  double get effectiveNavBarHeight {
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;
    
    return 88 + safeAreaBottom;
  }

  double get safeAreaBottom {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.bottom;
  }

  List<Widget>? _pages;

  @override
  void initState() {
    super.initState();
    
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize pages only once
    _pages ??= [
      MapPage(
        scaffoldKeyForBottomSheet: _scaffoldKey,
        onSearchFocusChanged: (active) {
          if (_hideNav != active) setState(() => _hideNav = active);
        },
        navBarHeight: effectiveNavBarHeight,
      ),
      FavouritesPage(),
      ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_pages == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      key: _scaffoldKey,
      // ── BODY ───────────────────────────────────────────────────────
      body: Scaffold(
        body: Stack(
          children: [
            // ── Pages & blocs in an IndexedStack ────────────────────
            MultiBlocProvider(
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
                child: IndexedStack(index: _tabIndex, children: _pages!),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black, // allow taps to pass through
                height: safeAreaBottom,
                width: double.infinity,
              ),
            ),
            // ── Overlay bottom navigation bar ───────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: IgnorePointer(
                  ignoring: _hideNav,
                  child: AnimatedSlide(
                    offset: _hideNav ? const Offset(0, 1) : Offset.zero,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: _hideNav ? 0 : 1,
                      duration: const Duration(milliseconds: 250),
                      // NO SafeArea → bar sits flush to bottom, no blank space
                      child: AnimatedBottomNavigationBar(
                        currentIndex: _tabIndex,
                        onTap: (i) => setState(() => _tabIndex = i),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  // helper for RouteOptionsSheet from children
  void showRouteOptionsSheet({
    required ValueNotifier<Map<TravelMode, RouteData>> routesNotifier,
    required TravelMode currentMode,
    required ValueChanged<TravelMode> onModeChanged,
    required VoidCallback onClose,
  }) {
    _scaffoldKey.currentState?.showBottomSheet(
      (_) => RouteOptionsSheet(
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
