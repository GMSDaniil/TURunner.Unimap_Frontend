import 'package:flutter/material.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/presentation/widgets/category_navigation.dart';

class MapSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final List<Pointer> suggestions;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final Function(String? category, Color? color) onCategorySelected;
  final Function(Pointer) onSuggestionSelected;

  const MapSearchBar({
    Key? key,
    required this.searchController,
    required this.suggestions,
    required this.onSearch,
    required this.onClear,
    required this.onCategorySelected,
    required this.onSuggestionSelected,
  }) : super(key: key);

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: widget.searchController,
                  enabled: true,
                  decoration: InputDecoration(
                    hintText: 'Search location',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: widget.onClear,
                    ),
                  ),
                  onSubmitted: widget.onSearch,
                ),
                const SizedBox(height: 8),
                CategoryNavigationBar(
                  onCategorySelected: widget.onCategorySelected,
                ),
                if (widget.suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = widget.suggestions[index];
                        return ListTile(
                          title: Text(suggestion.name),
                          onTap: () {
                            widget.onSuggestionSelected(suggestion);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
