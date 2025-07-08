import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'package:auth_app/data/favourites_manager.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/presentation/widgets/building_slide_window.dart';
import 'package:auth_app/presentation/widgets/weekly_mensa_plan.dart';
import 'package:auth_app/domain/usecases/get_mensa_menu.dart';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/service_locator.dart';

import 'package:auth_app/domain/usecases/add_favourite.dart';
import 'package:auth_app/domain/usecases/get_favourites.dart';
import 'package:auth_app/domain/usecases/delete_favourite.dart';
import 'package:auth_app/data/models/add_favourite_req_params.dart';
import 'package:auth_app/data/models/delete_favourite_req_params.dart';
import 'package:provider/provider.dart';
import 'package:auth_app/common/providers/user.dart';

/// Manages all info / coordinate bottom‐sheets that pop up from the map.
/// Every sheet is opened with **`showBottomSheet` on the root scaffold**
/// (passed in as a [GlobalKey]) so the map underneath stays interactive and
/// the sheet overlays the nav‐bar.
class BuildingPopupManager {
  // Holds at most one persistent sheet at a time.
  static PersistentBottomSheetController? _infoSheetController;

  /// ────────────────────────────────────────────────────────────────
  /// Building sheet (simple title + category + action buttons)
  /// ----------------------------------------------------------------
  static void showBuildingPopup({
    required BuildContext context,
    required Pointer pointer,
    required GlobalKey<ScaffoldState> scaffoldKey,
  }) {
    if (_infoSheetController != null) return; // already open

    _infoSheetController = scaffoldKey.currentState?.showBottomSheet(
      (ctx) => _SimpleBuildingSheet(pointer: pointer, onClose: _closeSheet),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );

    _infoSheetController?.closed.then((_) => _infoSheetController = null);
  }

  /// ────────────────────────────────────────────────────────────────
  /// Building slide window (fancy sheet with gradient buttons)
  /// ----------------------------------------------------------------
  static void showBuildingSlideWindow({
    required BuildContext context,
    required GlobalKey<ScaffoldState> scaffoldKey,
    required String title,
    required String category,
    required LatLng location,
    VoidCallback? onCreateRoute,
    required VoidCallback onClose,
  }) {
    if (_infoSheetController != null) return;

    final pointer = Pointer(
      name: title,
      lat: location.latitude,
      lng: location.longitude,
      category: category,
    );

    _infoSheetController = scaffoldKey.currentState?.showBottomSheet(
      (ctx) => BuildingSlideWindow(
        title: title,
        category: category,
        onShowMenu: category.toLowerCase() == 'canteen'
            ? () async {
                // Optional: Show loading indicator
                showDialog(
                  context: ctx,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final result = await sl<GetMensaMenuUseCase>().call(
                  param: GetMenuReqParams(mensaName: title),
                );

                // Remove loading indicator
                Navigator.of(ctx).pop();

                result.fold(
                  (error) => ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text('Error: $error'))),
                  (menu) => showModalBottomSheet(
                    context: ctx,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    builder: (_) => DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.6,
                      minChildSize: 0.4,
                      maxChildSize: 0.95,
                      builder: (context, scrollController) => WeeklyMensaPlan(
                        menu: menu,
                        scrollController: scrollController,
                      ),
                    ),
                  ),
                );
              }
            : null,
        onCreateRoute: onCreateRoute ?? () {},
        onAddToFavourites: () async {
          showDialog(
            context: ctx,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          final result = await sl<AddFavouriteUseCase>().call(
            param: AddFavouriteReqParams(
              name: pointer.name,
              latitude: pointer.lat,
              longitude: pointer.lng,
            ),
          );
          Navigator.of(ctx).pop();
          result.fold(
            (error) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Failed to add favourite: $error')),
              );
            },
            (_) async {
              final updated = await sl<GetFavouritesUseCase>().call();
              updated.fold(
                (error) => print('[DEBUG] Failed to reload favourites: $error'),
                (favs) {
                  print(
                    '[DEBUG] setFavourites called with ${favs.length} items',
                  );
                  Provider.of<UserProvider>(
                    ctx,
                    listen: false,
                  ).setFavourites(favs);
                },
              );
              _closeSheet();
              onClose();
            },
          );
        },
        onClose: _closeSheet,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );

    _infoSheetController?.closed.then((_) {
      _infoSheetController = null;
      onClose();
    });
  }

  /// ────────────────────────────────────────────────────────────────
  /// Coordinate or building‐less sheet (when user taps empty space)
  /// ----------------------------------------------------------------
  static void showBuildingOrCoordinatesPopup({
    required BuildContext context,
    required GlobalKey<ScaffoldState> scaffoldKey,
    required LatLng latlng,
    required String? buildingName,
    required String? category,
    VoidCallback? onCreateRoute,
  }) {
    if (_infoSheetController != null) return;

    _infoSheetController = scaffoldKey.currentState?.showBottomSheet(
      (ctx) => _CoordinateSheet(
        latlng: latlng,
        onCreateRoute:
            onCreateRoute ??
            () {
              _closeSheet();
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Route creation coming soon!')),
              );
            },
        onClose: _closeSheet,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );

    _infoSheetController?.closed.then((_) => _infoSheetController = null);
  }

  /// Helper to close & null‐out controller safely.
  static void _closeSheet() {
    _infoSheetController?.close();
    _infoSheetController = null;
  }

  // ────────────────────────────────────────────────────────────────
  // Support methods used only inside this manager
  // ----------------------------------------------------------------
  static Future<void> _showMensaMenu(BuildContext context) async {
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
            children: data
                .map<Widget>(
                  (meal) => ListTile(
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
                  ),
                )
                .toList(),
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
}

// ═════════════════════════════════════════════════════════════════
// Private sheet widgets
// ═════════════════════════════════════════════════════════════════

class _SimpleBuildingSheet extends StatefulWidget {
  final Pointer pointer;
  final VoidCallback onClose;
  const _SimpleBuildingSheet({required this.pointer, required this.onClose});

  @override
  State<_SimpleBuildingSheet> createState() => _SimpleBuildingSheetState();
}

class _SimpleBuildingSheetState extends State<_SimpleBuildingSheet> {
  @override
  Widget build(BuildContext context) {
    final favourites = Provider.of<UserProvider>(context).favourites;
    final isFavourite = favourites.any(
      (f) =>
          f.name == widget.pointer.name &&
          f.lat == widget.pointer.lat &&
          f.lng == widget.pointer.lng,
    );

    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // Building title & category
              Text(
                widget.pointer.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                widget.pointer.category,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Mensa menu button if applicable
              if (widget.pointer.category == 'Canteen')
                ElevatedButton(
                  onPressed: () => BuildingPopupManager._showMensaMenu(context),
                  child: const Text("Today's Meal Menu"),
                ),

              // Add/remove to favourites
              GradientActionButton(
                onPressed: () async {
                  if (isFavourite) {
                    // Remove from favourites
                    final fav = favourites.firstWhere(
                      (f) => f.name == widget.pointer.name,
                    );
                    final result = await sl<DeleteFavouriteUseCase>().call(
                      param: DeleteFavouriteReqParams(favouriteId: fav.id),
                    );
                    result.fold(
                      (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to remove favourite: $error'),
                          ),
                        );
                      },
                      (_) async {
                        final updated = await sl<GetFavouritesUseCase>().call();
                        updated.fold(
                          (error) {},
                          (favs) => Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).setFavourites(favs),
                        );
                      },
                    );
                  } else {
                    // Add to favourites
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                    final result = await sl<AddFavouriteUseCase>().call(
                      param: AddFavouriteReqParams(
                        name: widget.pointer.name,
                        latitude: widget.pointer.lat,
                        longitude: widget.pointer.lng,
                      ),
                    );
                    Navigator.of(context).pop();
                    result.fold(
                      (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add favourite: $error'),
                          ),
                        );
                      },
                      (_) async {
                        final updated = await sl<GetFavouritesUseCase>().call();
                        updated.fold(
                          (error) {},
                          (favs) => Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).setFavourites(favs),
                        );
                        setState(() {});
                      },
                    );
                  }
                },
                icon: isFavourite ? Icons.check : Icons.favorite_border,
                label: isFavourite
                    ? 'Saved in Favourites'
                    : 'Add to Favourites',
                colors: isFavourite
                    ? const [Color(0xFFFFC1A1), Color(0xFFFF8C94)]
                    : const [Colors.deepOrange, Colors.orange],
              ),

              // Close
              ElevatedButton(
                onPressed: widget.onClose,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoordinateSheet extends StatelessWidget {
  final LatLng latlng;
  final VoidCallback onCreateRoute;
  final VoidCallback onClose;

  const _CoordinateSheet({
    required this.latlng,
    required this.onCreateRoute,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Material(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            // This padding + Column matches your original modal style
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

                // Title “Coordinates” + actual lat,lon
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
                            '${latlng.latitude.toStringAsFixed(6)}, '
                            '${latlng.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Close “X” button at top‐right
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

                // Gradient pill button — back to original look
                GradientActionButton(
                  onPressed: onCreateRoute,
                  icon: Icons.directions,
                  label: 'Create Route',
                  colors: const [
                    Color(0xFF7B61FF), // purple → pink gradient
                    Color(0xFFB750FF),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
