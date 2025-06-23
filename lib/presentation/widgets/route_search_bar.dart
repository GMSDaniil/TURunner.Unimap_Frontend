import 'package:flutter/material.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/presentation/widgets/search_bar.dart';

/// A thin wrapper around MapSearchBar that
/// (a) forces showCategories=false
/// (b) no‐ops onCategorySelected
/// so you get exactly the same pill + suggestions UI,
/// but never see any chips.
class RouteSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final List<Pointer> suggestions;
  final ValueChanged<Pointer> onSuggestionSelected;
  final VoidCallback onClear;
  final FocusNode? focusNode;
  final VoidCallback onBack;                // ← NEW

  const RouteSearchBar({
    Key? key,
    required this.searchController,
    required this.suggestions,
    required this.onSuggestionSelected,
    required this.onClear,
    this.focusNode,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return MapSearchBar(
      searchController: searchController,
      suggestions: suggestions,
      onSearch: (_) {},                 // handled by suggestions
      onClear: onClear,
      onCategorySelected: (_, __) {},   // never show categories
      onSuggestionSelected: onSuggestionSelected,
      focusNode: focusNode,
      showCategories: false,            // hide the chips permanently
      onBack: onBack,                   // hand arrow-back press to caller
    );
  }
}