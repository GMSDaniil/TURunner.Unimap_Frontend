import 'package:flutter/material.dart';
import '../widgets/fullpage_search.dart';

class MapSearchBarWithFullPage extends StatefulWidget {
  final TextEditingController searchController;
  final List suggestions;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final Function(String?, Color?) onCategorySelected;
  final Function(dynamic) onSuggestionSelected;

  const MapSearchBarWithFullPage({
    Key? key,
    required this.searchController,
    required this.suggestions,
    required this.onSearch,
    required this.onClear,
    required this.onCategorySelected,
    required this.onSuggestionSelected,
  }) : super(key: key);

  @override
  State<MapSearchBarWithFullPage> createState() => _MapSearchBarWithFullPageState();
}

class _MapSearchBarWithFullPageState extends State<MapSearchBarWithFullPage> {
  bool _isSearchActive = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isSearchActive = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FullPageSearch(
      isActive: _isSearchActive,
      searchBarHeight: 64.0,
      onClose: () {
        _focusNode.unfocus();
        setState(() => _isSearchActive = false);
      },
      searchBar: Material(
        color: Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: widget.searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search here',
              prefixIcon: Icon(Icons.search),
              suffixIcon: widget.searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: widget.onClear,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (q) => setState(() {}),
            onSubmitted: widget.onSearch,
          ),
        ),
      ),
      suggestions: widget.suggestions.map<Widget>((s) {
        return ListTile(
          title: Text(s.name),
          onTap: () => widget.onSuggestionSelected(s),
        );
      }).toList(),
    );
  }
}
