// bottom_navigation.dart
import 'dart:ui' show lerpDouble;

import 'package:auth_app/core/configs/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;      // ← for min()

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY CHIPS (top of the map)
// ─────────────────────────────────────────────────────────────────────────────
class CategoryNavigationBar extends StatelessWidget {
  final Function(String category, Color color) onCategorySelected;

  const CategoryNavigationBar({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            [
                  _categoryWidget(
                    icon: Icons.my_location,
                    label: 'Current Location',
                    iconColor: Colors.blue,
                    onTap: () {
                      // TODO: current location functionality
                    },
                  ),
                  _categoryWidget(
                    icon: Icons.local_cafe,
                    label: 'Café',
                    iconColor: Color(0xFFB89B8A), // Café brown
                    onTap: () => onCategorySelected('Café', Color(0xFFB89B8A)),
                  ),
                  _categoryWidget(
                    icon: Icons.local_library,
                    label: 'Library',
                    iconColor: Color(0xFFF9A94A), // Library orange
                    onTap: () => onCategorySelected('Library', Color(0xFFF9A94A)),
                  ),
                  _categoryWidget(
                    icon: Icons.restaurant,
                    label: 'Mensa',
                    iconColor: Color(0xFF5BA172), // Mensa green
                    onTap: () => onCategorySelected('Mensa', Color(0xFF5BA172)),
                  )
                  // add more chips here if you like
                ]
                .map(
                  (chip) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: chip,
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _categoryWidget({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAVIGATION BAR
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AnimatedBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = <_NavTab>[
    _NavTab(Icons.map, 'Map'),
    _NavTab(Icons.favorite, 'Favourites'),
    _NavTab(Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.only(top: 0), // space above bar
        child: Material(
          color: Colors.transparent,
          elevation: 10, // no shadow line
          child: Ink(
            decoration: BoxDecoration(
              gradient: Theme.of(context).primaryGradient,
            ),
            child: SizedBox(
              height: 88, // ▲ taller bar
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final tab = _tabs[i];
                    return Expanded(
                      child: InkResponse(
                        onTap: () => onTap(i),
                        containedInkWell: false,
                        splashColor: Colors.white24,
                        highlightColor: Colors.white10,
                        radius: MediaQuery.of(context).size.width,
                        child: _AnimatedNavIcon(
                          icon: tab.icon,
                          label: tab.label,
                          selected: i == currentIndex,
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
    );
  }
}

// ─── Animated Icon + Label (fade-&-slide, width collapses) ────────────────
class _AnimatedNavIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _AnimatedNavIcon({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _t; // 0 = idle | 1 = selected

  static const _duration = Duration(milliseconds: 320);
  static const _iconSize = 32.0;
  static const _iconShift = -10.0; // icon slides left
  static const _labelSlide = -6.0; // label starts 6 px left

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);
    _t = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.value = widget.selected ? 1 : 0; // no flash on first build
  }

  @override
  void didUpdateWidget(covariant _AnimatedNavIcon old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      widget.selected ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Let the Expanded-cell tell us how wide it can be
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxCellW = constraints.maxWidth;            // full cell width

          return AnimatedBuilder(
            animation: _t,
            builder: (context, _) {
              final t = _t.value;                           // 0 → 1

              // Measure label once so we know how much text we *could* show
              final tp = TextPainter(
                text: TextSpan(
                  text: widget.label,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                textDirection: TextDirection.ltr,
              )..layout();
              final textW = tp.width;

              // ── desired geometry ────────────────────────────────────────────
              const double iconOnlyW = _iconSize + 28;      // icon + fat padding
              final double wantFullW =                       // icon + gap + text + padding
                  _iconSize + 8 + textW + 40;

              // Let the pill grow to the width we actually want. It can now
              // exceed the parent cell — we’ll allow that with an OverflowBox.
              final double bubbleW = lerpDouble(iconOnlyW, wantFullW, t)!;

              const double bubbleH = 60;                    // BIGGER pill

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OverflowBox(                    // ← NEW
                  minWidth: 0,
                  maxWidth: double.infinity,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ───────── pill bubble ─────────
                      Opacity(
                        opacity: t,
                        child: Transform.scale(
                          scale: lerpDouble(0.4, 1.0, t)!,     // “pop”
                          child: Container(
                            width: bubbleW,
                            height: bubbleH,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(bubbleH / 2),
                            ),
                          ),
                        ),
                      ),

                      // ─────── icon + label ────────
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(_iconShift * t, 0),
                            child: Icon(
                              widget.icon,
                              size: _iconSize,
                              color: Color.lerp(Colors.white, Colors.amber, t),
                            ),
                          ),
                          SizedBox(width: lerpDouble(0, 6, t)!),   // gap
                          ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: t,
                              child: Opacity(
                                opacity: t,
                                child: Transform.translate(
                                  offset: Offset(_labelSlide * (1 - t), 0),
                                  child: Text(
                                    widget.label,
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private data class for the tabs
// ─────────────────────────────────────────────────────────────────────────────
class _NavTab {
  final IconData icon;
  final String label;
  const _NavTab(this.icon, this.label);
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final AnimationController _searchCtrl;
  late final Animation<double> _searchAnim;
  bool _searchActive = false;

  // For demo we just randomize this
  final _rnd = math.Random();
  var _weather = [
    '☀️ 24°C',
    '☁️ 22°C',
    '🌧 18°C',
    '❄️ 0°C',
  ];
  var _selectedWeather = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _searchAnim = CurvedAnimation(parent: _searchCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
    });
    if (_searchActive) {
      _searchCtrl.forward();
    } else {
      _searchCtrl.reverse();
    }
  }

  void _goToCurrentLocation({bool moveMap = false}) {
    // TODO: implement current location functionality
  }

  void _changeWeather() {
    setState(() {
      _selectedWeather = (_selectedWeather + 1) % _weather.length;
    });
  }

  static const _animDuration = Duration(milliseconds: 250);
  static const double _navBarHeight = 88;        // ← height of bottom-nav

  // ────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ─────────────────── Map Widget (placeholder) ───────────────────
          Container(
            color: Colors.blue[50],
            child: Center(
              child: Text(
                '🗺️ Map View',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ),

          // ─────────────────── Search Field + Current Location Button ───────────────────
          AnimatedBuilder(
            animation: _searchCtrl,
            builder: (context, child) {
              return Stack(
                children: [
                  // Search field
                  Positioned(
                    top: 40,
                    left: 20,
                    right: 20,
                    child: ScaleTransition(
                      scale: _searchAnim,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  border: InputBorder.none,
                                ),
                                onTap: () {
                                  // TODO: implement search functionality
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                // TODO: clear search field
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Current location button (FAB)
                  _buildCurrentLocationButton(),
                ],
              );
            },
          ),

          // ─────────────────── Weather pill with fade+slide animation ───────────────────
          Positioned(
            left: 16,
            bottom: 16 + _navBarHeight,
            child: FadeTransition(
              opacity: _searchAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(_searchAnim),
                child: GestureDetector(
                  onTap: _changeWeather,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _weather[_selectedWeather],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.blueGrey[800],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─────────────────── Bottom Navigation Bar ───────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBottomNavigationBar(
              currentIndex: 0,
              onTap: (index) {
                // TODO: handle bottom nav tap
              },
            ),
          ),
        ],
      ),
    );
  }

  // Always keep widgets 20 px above the nav bar’s top edge.
  // (They’ll fade/slide away when the search bar is focused.)
  double get _bottomOffset => 20 + _navBarHeight;

  Widget _buildCurrentLocationButton() => Positioned(
        bottom: _bottomOffset,
        right: 20,
        child: AnimatedSlide(
          offset: _searchActive ? const Offset(0, 1) : Offset.zero,
          duration: _animDuration,
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            opacity: _searchActive ? 0 : 1,
            duration: _animDuration,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () => _goToCurrentLocation(moveMap: true),
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ),
      );
}
