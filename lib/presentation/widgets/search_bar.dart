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
  final bool showCategories; // ← NEW
  final VoidCallback? onBack;           // ← NEW optional callback
  final bool includeBottomSafeArea;     // ← NEW  (defaults to true)

  const MapSearchBar({
    Key? key,
    required this.searchController,
    required this.suggestions,
    required this.onSearch,
    required this.onClear,
    required this.onCategorySelected,
    required this.onSuggestionSelected,
    this.focusNode,
    this.showCategories = true, // ← NEW
    this.onBack,                           // ← NEW
    this.includeBottomSafeArea = true,     // ← NEW
  }) : super(key: key);

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  late FocusNode _focusNode;
  final GlobalKey _suggestionsKey = GlobalKey(); // ← NEW
  final double _navBarHeight = 88; // Fixed height for the navigation bar

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
    // show the “×” only when there’s something to clear
    final showClose = hasText;
    // decide which leading icon to show
    final Widget _leadingIcon = hasFocus
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            splashRadius: 20,
            padding: EdgeInsets.zero,        // keep exactly same inset
            onPressed: () {
              // clear text first
              widget.searchController.clear();
              widget.onClear();
              // if a special back-handler is provided → use it
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                _focusNode.unfocus();        // default: just unfocus
              }
              setState(() {});
            },
          )
        : Icon(Icons.search, color: Colors.grey[700]);

    // 1) figure out where our suggestions area starts
    double topY;
    if (!widget.showCategories) {
      // In route creation overlay: leave 24px for visual breathing room
      topY = 24;
    } else if (_suggestionsKey.currentContext != null) {
      // On main map page: measure as before
      final box =
          _suggestionsKey.currentContext!.findRenderObject() as RenderBox;
      topY = box.localToGlobal(Offset.zero).dy;
    } else {
      topY = 0;
    }

    // 2) compute exactly how much vertical space remains
    final bottomInset = widget.includeBottomSafeArea
        ? MediaQuery.of(context).padding.bottom
        : 0.0;
    final availableHeight =
        MediaQuery.of(context).size.height -
        topY -
        bottomInset -
        _navBarHeight; // ← subtract your 88px nav bar

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeArea(
          bottom: widget.includeBottomSafeArea,
          child: Padding(
            key: _suggestionsKey, // ← ATTACH KEY HERE
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
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
                            // show ⟵ when focused, otherwise magnifier
                            prefixIcon: _leadingIcon,
                            suffixIcon: const SizedBox.shrink(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: borderRadius,
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: borderRadius,
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.65),
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
                              // × only clears the field, keeps focus
                              widget.searchController.clear();
                              widget.onClear();
                              setState(() {});   // rebuild to hide button
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Animated collapse/expand of category chips ─────────
                if (widget.showCategories)
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

                // 3) use exactly that leftover height
                if (widget.suggestions.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: availableHeight),
                    child: _buildSuggestionsDropdown(),
                  ),
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
      color: Colors.white,
      child: ListView.separated(
        itemCount: widget.suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade300,
          indent: 56, // ← start 56px in (icon + padding)
          endIndent: 16, // ← leave 16px padding on right
        ),
        itemBuilder: (context, index) {
          final suggestion = widget.suggestions[index];
          return ListTile(
            leading: const Icon(
              Icons.location_on_outlined,
              size: 22,
              color: Colors.grey,
            ),
            title: Text(
              suggestion.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
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
