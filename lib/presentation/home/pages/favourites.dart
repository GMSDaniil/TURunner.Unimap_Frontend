import 'package:flutter/material.dart';
import 'package:auth_app/core/configs/theme/app_theme.dart';
import 'package:auth_app/data/favourites_manager.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).primaryGradient;

    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: Text('Favourites', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
      //   centerTitle: true ,
      //   automaticallyImplyLeading: false,
      // ),
      body: SafeArea(
        child: Stack(
          children: [
            FavouritesManager().favourites.isEmpty
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
                    itemCount: FavouritesManager().favourites.length,
                    itemBuilder: (context, index) {
                      final pointer = FavouritesManager().favourites[index];
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
                            pointer.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(pointer.category),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                FavouritesManager().remove(pointer);
                              });
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
