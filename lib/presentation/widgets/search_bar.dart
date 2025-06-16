import 'package:flutter/material.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/presentation/widgets/category_navigation.dart';

/// Refreshed search bar that is *always* pill‑shaped, has a soft shadow,
/// and keeps a subtle TU‑Berlin accent when focused. The prefix search icon
/// is now a regular grey icon (no gradient chip).
class MapSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final List<Pointer> suggestions;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final Function(String? category, Color? color) onCategorySelected;
  final Function(Pointer) onSuggestionSelected;
  final FocusNode? focusNode;

  const MapSearchBar({
    Key? key,
    required this.searchController,
    required this.suggestions,
    required this.onSearch,
    required this.onClear,
    required this.onCategorySelected,
    required this.onSuggestionSelected,
    this.focusNode,
  }) : super(key: key);

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    if (widget.focusNode == null) {
      _focusNode.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(28);
    final hasText = widget.searchController.text.isNotEmpty;
    final hasFocus = _focusNode.hasFocus;
    final showClose = hasText || hasFocus;

    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8), // ← bumped top from 8→16
            child: Column(
              children: [
                // ── Search Field with Close Button ───────────────────────
                Material(
                  color: Colors.transparent,
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: borderRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          focusNode: _focusNode,
                          onChanged: (_) => setState(() {}),
                          controller: widget.searchController,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search location',
                            prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                            suffixIcon: const SizedBox.shrink(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: borderRadius,
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: borderRadius,
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.65),
                                width: 2,
                              ),
                            ),
                          ),
                          onSubmitted: (value) {
                            // perform search, then clear and unfocus
                            widget.onSearch(value);
                            widget.searchController.clear();
                            widget.onClear();
                            _focusNode.unfocus();
                            setState(() {});
                          },
                        ),
                      ),

                      if (showClose)
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            splashRadius: 16,
                            padding: const EdgeInsets.all(4),
                            onPressed: () {
                              widget.searchController.clear();
                              widget.onClear();
                              _focusNode.unfocus();
                              setState(() {}); // rebuild to hide button
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Animated collapse/expand of category chips ─────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.2),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: hasFocus
                      ? const SizedBox(key: ValueKey('hidden_chips'))
                      : CategoryNavigationBar(
                          key: const ValueKey('visible_chips'),
                          onCategorySelected: widget.onCategorySelected,
                        ),
                ),

                // ── Suggestions dropdown ─────────────────────────────────
                if (widget.suggestions.isNotEmpty) _buildSuggestionsDropdown(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 250),
      color: Colors.white,                           // flat, 2-D background
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: widget.suggestions.length,
        separatorBuilder: (_, __) => Divider(        // grey separators
          height: 1,
          thickness: 1,
          color: Colors.grey.shade300,
        ),
        itemBuilder: (context, index) {
          final suggestion = widget.suggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on_outlined, size: 20),
            title: Text(suggestion.name),
            onTap: () {
              // clear text, hide suggestions, unfocus, then select
              widget.searchController.clear();
              widget.onClear();
              _focusNode.unfocus();
              setState(() {});
              widget.onSuggestionSelected(suggestion);
            },
          );
        },
      ),
    );
  }
}