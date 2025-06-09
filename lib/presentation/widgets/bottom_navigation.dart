// bottom_navigation.dart
import 'dart:ui' show lerpDouble;

import 'package:auth_app/core/configs/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
    return Center(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final t = _t.value; // 0-1 tween value
          return Padding(
            padding: const EdgeInsets.only(bottom: 8), // <-- Add this line (adjust value as needed)
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─ Icon ─
                Transform.translate(
                  offset: Offset(_iconShift * t, 0),
                  child: Icon(
                    widget.icon,
                    size: _iconSize,
                    color: Color.lerp(Colors.white, Colors.amber, t),
                  ),
                ),

                // ─ Gap (0 → 1 px) ─ Further reduced to make icon and text closer
                SizedBox(width: lerpDouble(0, 1, t)!),

                // ─ Label ─   <----------------------------------------
                /* old block was here */

                // NEW: label width collapses with Align.widthFactor,
                //      while still fading + sliding in.
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: t, // 0 = no width
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
                // ───────────────────────────────────────────────────
              ],
            ),
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
