import 'package:flutter/material.dart';
import 'package:auth_app/core/configs/theme/app_theme.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final List<String> _favorites = [];

  void _addDummyFavorite() {
    setState(() {
      _favorites.add('Favorite Place #${_favorites.length + 1}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).primaryGradient;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Favourites'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          _favorites.isEmpty
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
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading:
                            const Icon(Icons.favorite, color: Colors.pink),
                        title: Text(
                          _favorites[index],
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              _favorites.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),

          // Floating "Add" button
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: _addDummyFavorite,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
