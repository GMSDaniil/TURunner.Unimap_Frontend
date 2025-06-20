import 'package:flutter/material.dart';
import 'package:auth_app/presentation/widgets/weekly_mensa_plan.dart';
import 'package:auth_app/presentation/home/pages/mensa.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:auth_app/domain/usecases/get_mensa_menu.dart';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/service_locator.dart';

/// Re-usable gradient pill button used throughout the bottom sheet.
class GradientActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final List<Color> colors;

  const GradientActionButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      splashColor: Colors.white24,
      onTap: onPressed,
      child: Ink(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet that appears when a POI is selected on the map.
/// Background is pure white, buttons keep TU-Berlin gradient, and the layout
/// has been refined for a cleaner look reminiscent of Google Maps.
class BuildingSlideWindow extends StatelessWidget {
  final String title;
  final String category;
  final VoidCallback onCreateRoute;
  final VoidCallback onAddToFavourites;
  final VoidCallback onClose;
  final VoidCallback? onShowMenu;
  final PanelController? panelController;

  const BuildingSlideWindow({
    Key? key,
    required this.title,
    required this.category,
    required this.onCreateRoute,
    required this.onAddToFavourites,
    required this.onClose,
    required this.onShowMenu,
    this.panelController,
  }) : super(key: key);

  // quick access to brand colours (taken from profile-screen gradient)
  static const _purple = Color(0xFF7B61FF);
  static const _pink = Color(0xFFB750FF);
  static const _orange = Color(0xFFFF3C2A);
  static const _deepOrange = Color(0xFFFF6E3B);

  bool get isCanteen =>
      category.trim().toLowerCase() == 'canteen' ||
      category.trim().toLowerCase() == 'mensa';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: Colors.white, // explicit white background
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Default handle for all panels
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header: title & small circular close button aligned with top of title
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // align children to top
                    children: [
                      // Title + category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // smaller circular close button, no top margin
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          splashRadius: 16,
                          padding: const EdgeInsets.all(4),
                          onPressed: onClose,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Row of action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GradientActionButton(
                          onPressed: onCreateRoute,
                          icon: Icons.directions,
                          label: 'Create Route',
                          colors: const [_purple, _pink],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GradientActionButton(
                          onPressed: onAddToFavourites,
                          icon: Icons.favorite_border,
                          label: 'Add to Favourites',
                          colors: const [_deepOrange, _orange],
                        ),
                      ),
                    ],
                  ),
                  if (isCanteen && onShowMenu != null) ...[
                    const SizedBox(height: 16),
                    GradientActionButton(
                      onPressed: onShowMenu!,
                      icon: Icons.restaurant_menu,
                      label: 'Show Mensa Plan',
                      colors: const [Color(0xFF4CAF50), Color(0xFF43A047)],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
