import 'package:auth_app/common/bloc/button/button_state_cubit.dart';
import 'package:auth_app/common/bloc/button/button_state.dart';
import 'package:auth_app/presentation/home/bloc/user_display_cubit.dart';
import 'package:auth_app/presentation/home/bloc/user_display_state.dart';
import 'package:auth_app/presentation/home/pages/favourites.dart';
import 'package:auth_app/presentation/home/pages/map.dart';
import 'package:auth_app/presentation/home/pages/profile.dart';
import 'package:auth_app/presentation/home/pages/welcome.dart';
import 'package:auth_app/core/configs/theme/app_theme.dart';
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

  static const _tabs = <_NavTab>[
    _NavTab(Icons.map, 'Map'),
    _NavTab(Icons.favorite, 'Favourites'),
    _NavTab(Icons.person, 'Profile'),
  ];

  final widgetList = const [
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

      // ─── Bottom Navigation Bar (Clean, No Top Line) ────────────────────────
      bottomNavigationBar: ClipRect(
        child: Padding(
          padding: const EdgeInsets.only(top: 0), // space above bar
          child: Material(
            color: Colors.transparent,
            elevation: 0, // prevent shadow line
            child: Ink(
              decoration: BoxDecoration(
                gradient: Theme.of(context).primaryGradient,
              ),
              child: SizedBox(
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final tab = _tabs[i];
                      final selected = i == myIndex;

                      return Expanded(
                        child: InkResponse(
                          onTap: () => setState(() => myIndex = i),
                          containedInkWell: false,
                          splashColor: Colors.white24,
                          highlightColor: Colors.white10,
                          radius: MediaQuery.of(context).size.width,
                          child: _AnimatedNavIcon(
                            icon: tab.icon,
                            label: tab.label,
                            selected: selected,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Icon + Label ───────────────────────────────────────────────────

class _AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _AnimatedNavIcon({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final iconOffset = Tween<double>(begin: 0, end: -6);
    final labelOffsetBegin = const Offset(0, 0.3);
    final labelOffsetEnd = Offset.zero;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            0,
            selected ? iconOffset.end! : iconOffset.begin!,
            0,
          ),
          child: Icon(
            icon,
            size: 28,
            color: selected ? Colors.amber : Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          offset: selected ? labelOffsetEnd : labelOffsetBegin,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: selected ? 1 : 0,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Nav Tab Data Holder ────────────────────────────────────────────────────

class _NavTab {
  final IconData icon;
  final String label;
  const _NavTab(this.icon, this.label);
}
