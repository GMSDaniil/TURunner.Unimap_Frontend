import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/data/favourites_manager.dart';
import 'package:auth_app/presentation/widgets/building_popup.dart';
import 'package:auth_app/presentation/widgets/building_slide_window.dart';
import 'package:latlong2/latlong.dart';

class BuildingPopupManager {
  /// Shows a modal bottom sheet with building information and action buttons
  static void showBuildingPopup(BuildContext context, Pointer pointer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Makes the bottom sheet full width
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Building name
              Text(
                pointer.name,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                pointer.category,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Show the menu button only for Mensa buildings
              if (pointer.category == 'Mensa')
                _buildMensaMenuButton(context),
              _buildFavoritesButton(context, pointer),
              // Close button
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Button to show the Mensa menu
  static Widget _buildMensaMenuButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final jsonStr = await rootBundle.loadString(
          'assets/sample_mensa_menu.json',
        );
        final List data = jsonDecode(jsonStr);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Today's Menu"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: data.map<Widget>((meal) => ListTile(
                  title: Text(meal['name']),
                  subtitle: Text(
                    'Student: ${meal['priceStudent']} € | Employee: ${meal['priceEmployee']} € | Guest: ${meal['priceGast']} €',
                  ),
                  trailing: meal['vegan'] == true
                    ? const Icon(Icons.eco, color: Colors.green)
                    : meal['vegetarian'] == true
                      ? const Icon(Icons.spa, color: Colors.orange)
                      : null,
                )).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text("Today's Meal Menu"),
    );
  }

  /// Button to add to favorites
  static Widget _buildFavoritesButton(BuildContext context, Pointer pointer) {
    return ElevatedButton.icon(
      onPressed: () {
        FavouritesManager().add(pointer);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pointer.name} added to favourites!'),
          ),
        );
      },
      icon: const Icon(Icons.favorite, color: Colors.white),
      label: const Text('Add to Favourites'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        elevation: 2,
      ),
    );
  }

  /// Close button
  static Widget _buildCloseButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('Close'),
    );
  }

  /// Shows the building slide window with detailed information and actions
  static void showBuildingSlideWindow({
    required BuildContext context,
    required String title,
    required String category,
    required LatLng location,
    VoidCallback? onCreateRoute,
    required VoidCallback onClose,
  }) {
    final pointer = Pointer(
      name: title,
      lat: location.latitude,
      lng: location.longitude,
      category: category,
    );
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BuildingSlideWindow(
        title: title,
        category: category,
        onShowMenu: category == 'Mensa'
            ? () async {
                final jsonStr = await rootBundle.loadString(
                  'assets/sample_mensa_menu.json',
                );
                final List data = jsonDecode(jsonStr);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Today's Meal Menu"),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children: data.map<Widget>((meal) {
                          return ListTile(
                            title: Text(meal['name']),
                            subtitle: Text(
                              'Student: ${meal['priceStudent']} € | '
                              'Employee: ${meal['priceEmployee']} € | '
                              'Guest: ${meal['priceGast']} €',
                            ),
                            trailing: meal['vegan'] == true
                                ? const Icon(Icons.eco, color: Colors.green)
                                : meal['vegetarian'] == true
                                    ? const Icon(Icons.spa, color: Colors.orange)
                                    : null,
                          );
                        }).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            : null,
        onCreateRoute: onCreateRoute ?? () {
          // Default route logic
        },
        onAddToFavourites: () {
          FavouritesManager().add(pointer);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pointer.name} added to favourites!')),
          );
        },
        onClose: onClose,
      ),
    );
  }
  
  /// Shows either a building slide window or coordinates popup based on whether a building was found
  static void showBuildingOrCoordinatesPopup({
    required BuildContext context,
    required LatLng latlng,
    required String? buildingName,
    required String? category,
    VoidCallback? onCreateRoute,
  }) {
    if (buildingName != null && category != null) {
      showBuildingSlideWindow(
        context: context,
        title: buildingName,
        category: category,
        location: latlng,
        onCreateRoute: onCreateRoute,
        onClose: () => Navigator.of(context).pop(),
      );
    } else {
      // For coordinates-only popup, we'll create a custom bottom sheet with route button
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Title and coordinates
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Coordinates',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${latlng.latitude.toStringAsFixed(6)}, ${latlng.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Close button
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Create Route button - using the same GradientActionButton from BuildingSlideWindow
              GradientActionButton(
                onPressed: onCreateRoute ?? () {
                  // Default route logic if none provided
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Route creation from coordinates coming soon!')),
                  );
                },
                icon: Icons.directions,
                label: 'Create Route',
                colors: const [Color(0xFF7B61FF), Color(0xFFB750FF)], // Same colors as in BuildingSlideWindow
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// Simple implementation of GradientActionButton for use in coordinate popup
/// (This could be moved to its own file if needed elsewhere)
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
