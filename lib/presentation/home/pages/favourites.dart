import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_app/common/providers/user.dart';
import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/domain/usecases/delete_favourite.dart';
import 'package:auth_app/domain/usecases/get_favourites.dart';
import 'package:auth_app/core/configs/theme/app_theme.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/data/models/delete_favourite_req_params.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  Set<String> deletingIds = {};
  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).primaryGradient;
    final favourites = Provider.of<UserProvider>(context).favourites;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            favourites.isEmpty
                ? Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => gradient.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        'You haven’t added any favourites yet.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: favourites.length,
                    itemBuilder: (context, index) {
                      final fav = favourites[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.favorite,
                            color: Colors.pink,
                          ),
                          title: Text(
                            fav.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            // Disable button if this favourite is currently being deleted
                            onPressed: deletingIds.contains(fav.id)
                                ? null // Button is disabled while deleting
                                : () async {
                                    setState(() {
                                      deletingIds.add(fav.id);
                                    });

                                    final result =
                                        await sl<DeleteFavouriteUseCase>().call(
                                          param: DeleteFavouriteReqParams(
                                            favouriteId: fav.id.toString(),
                                          ),
                                        );

                                    if (!mounted) return;

                                    result.fold(
                                      (error) async {
                                        if (!mounted) return;
                                        // error is always a String from your repository/usecase
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to delete: $error',
                                            ),
                                          ),
                                        );
                                        final getResult =
                                            await sl<GetFavouritesUseCase>()
                                                .call();
                                        if (!mounted) return;
                                        getResult.fold((error) {}, (
                                          freshFavourites,
                                        ) {
                                          Provider.of<UserProvider>(
                                            context,
                                            listen: false,
                                          ).setFavourites(freshFavourites);
                                        });
                                      },
                                      (_) async {
                                        if (!mounted) return;
                                        final getResult =
                                            await sl<GetFavouritesUseCase>()
                                                .call();
                                        if (!mounted) return;
                                        getResult.fold((error) {}, (
                                          freshFavourites,
                                        ) {
                                          Provider.of<UserProvider>(
                                            context,
                                            listen: false,
                                          ).setFavourites(freshFavourites);
                                        });
                                      },
                                    );

                                    if (mounted) {
                                      setState(() {
                                        deletingIds.remove(fav.id);
                                      });
                                    }
                                  },
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
