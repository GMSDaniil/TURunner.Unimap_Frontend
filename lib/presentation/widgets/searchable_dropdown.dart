import 'package:flutter/material.dart';
import 'package:auth_app/domain/entities/study_program.dart';

class SearchableDropdown extends StatefulWidget {
  final List<StudyProgramEntity> items;
  final StudyProgramEntity? selectedItem;
  final Function(StudyProgramEntity) onChanged;
  final String hintText;
  final bool isLoading;
  final void Function(bool)? onFocusChanged;

  const SearchableDropdown({
    Key? key,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    this.hintText = 'Search study programs...',
    this.isLoading = false,
    this.onFocusChanged,
  }) : super(key: key);

  @override
  SearchableDropdownState createState() => SearchableDropdownState();
}

class SearchableDropdownState extends State<SearchableDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<StudyProgramEntity> _filteredItems = [];
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    if (widget.selectedItem != null) {
      _searchController.text = widget.selectedItem!.name;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _filteredItems = widget.items;
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isOpen) {
      _openDropdown();
    } else if (!_focusNode.hasFocus && _isOpen) {
      _closeDropdown();
    }
    // Notify parent about focus change
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  void _openDropdown() {
    if (_isOpen || widget.items.isEmpty) return;

    setState(() => _isOpen = true);
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
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

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
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
                        shrinkWrap: true,
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
    setState(() {
      _searchController.text = item.name;
    });
    widget.onChanged(item);
    _focusNode.unfocus();
    _closeDropdown();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.stupoNumber.contains(query))
          .toList();
    });
    
    // Update overlay
    if (_isOpen) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _searchController,
      focusNode: _focusNode,
      onChanged: _onSearchChanged,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: Colors.grey[100],
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
            : Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey[600],
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
    _searchController.dispose();
    _focusNode.dispose();
    _closeDropdown();
    super.dispose();
  }
}