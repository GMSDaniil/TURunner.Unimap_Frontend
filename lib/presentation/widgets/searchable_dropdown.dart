import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';  // ✅ Add this import
import 'package:auth_app/domain/entities/study_program.dart';

class SearchableDropdown extends StatefulWidget {
  final List<StudyProgramEntity> items;
  final StudyProgramEntity? selectedItem;
  final Function(StudyProgramEntity) onChanged;
  final String hintText;
  final bool isLoading;
  final void Function(bool)? onFocusChanged;

  const SearchableDropdown({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    this.hintText = 'Search study programs...',
    this.isLoading = false,
    this.onFocusChanged,
  });

  @override
  SearchableDropdownState createState() => SearchableDropdownState();
}

class SearchableDropdownState extends State<SearchableDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<StudyProgramEntity> _filteredItems = [];
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  ScrollPosition? _scrollPosition;
  
  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _focusNode.addListener(_onFocusChanged);
    
    // ✅ Initialize with selected item
    if (widget.selectedItem != null) {
      _searchController.text = widget.selectedItem!.name;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_updateOverlayPosition);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_updateOverlayPosition);
  }

  @override
  void didUpdateWidget(SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.items != oldWidget.items) {
      _filteredItems = widget.items;
      _updateOverlay();
    }
    
    if (widget.selectedItem != oldWidget.selectedItem) {
      _searchController.text = widget.selectedItem?.name ?? '';
    }
  }

  void _onFocusChanged() {
    final hasFocus = _focusNode.hasFocus;
    
    if (hasFocus && !_isOpen) {
      _openDropdown();
    } else if (!hasFocus && _isOpen) {
      _closeDropdown();
    }
    
    // ✅ Always notify parent about focus change
    widget.onFocusChanged?.call(hasFocus);
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;
    
    setState(() => _isOpen = true);  // ✅ Add this line
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    
    // ✅ Add keyboard listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {}); // Trigger rebuild to recalculate position
      }
    });
  }

  void _closeDropdown() {
    if (!_isOpen) return;

    setState(() => _isOpen = false);
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    // ✅ Get keyboard and screen info
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double keyboardHeight = mediaQuery.viewInsets.bottom;
    final double screenHeight = mediaQuery.size.height;
    final double safeAreaTop = mediaQuery.padding.top;
    final double safeAreaBottom = mediaQuery.padding.bottom;
    
    // ✅ Calculate available space above and below the text field
    final double spaceAbove = offset.dy - safeAreaTop;
    final double spaceBelow = screenHeight - offset.dy - size.height - keyboardHeight - safeAreaBottom;
    
    // ✅ Determine if dropdown should appear above or below
    const double minDropdownHeight = 100.0;
    const double maxDropdownHeight = 200.0;
    
    final bool showAbove = spaceBelow < minDropdownHeight && spaceAbove > minDropdownHeight;
    final double availableHeight = showAbove ? spaceAbove : spaceBelow;
    final double dropdownHeight = availableHeight.clamp(minDropdownHeight, maxDropdownHeight);
    
    // ✅ Calculate position
    final double topPosition = showAbove 
        ? offset.dy - dropdownHeight - 4
        : offset.dy + size.height + 4;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: topPosition,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: dropdownHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: widget.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _filteredItems.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No study programs found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return InkWell(
                            onTap: () => _selectItem(item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: index < _filteredItems.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stupo: ${item.stupoNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  void _selectItem(StudyProgramEntity item) {
    // ✅ Update text field immediately
    _searchController.text = item.name;
    
    // ✅ Close dropdown first
    _focusNode.unfocus();
    _closeDropdown();
    
    // ✅ Schedule the callback for the next frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onChanged(item);
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.stupoNumber.contains(query))
          .toList();
    });
    
    _updateOverlay();
  }

  void _updateOverlay() {
    if (_overlayEntry != null && mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }
    
  // ✅ Update overlay position when scrolling
  void _updateOverlayPosition() {
    if (_overlayEntry != null && mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _searchController,
      focusNode: _focusNode,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
        suffixIcon: widget.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : GestureDetector(  // ✅ Wrap icon with GestureDetector
                onTap: () {
                  if (_isOpen) {
                    // ✅ Close dropdown and unfocus
                    _focusNode.unfocus();
                    _closeDropdown();
                  } else {
                    // ✅ Open dropdown and focus
                    _focusNode.requestFocus();
                    _openDropdown();
                  }
                },
                child: Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ),
      ),
    );
  }

  void closeDropdown() {
    _focusNode.unfocus();
    _closeDropdown();
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_updateOverlayPosition);
    _searchController.dispose();
    _focusNode.dispose();
    _closeDropdown();
    super.dispose();
  }
}