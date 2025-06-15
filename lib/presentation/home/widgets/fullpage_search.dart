import 'package:flutter/material.dart';

class FullPageSearch extends StatefulWidget {
  final Widget searchBar;
  final List<Widget> suggestions;
  final bool isActive;
  final VoidCallback onClose;
  final double searchBarHeight;

  const FullPageSearch({
    Key? key,
    required this.searchBar,
    required this.suggestions,
    required this.isActive,
    required this.onClose,
    this.searchBarHeight = 64.0,
  }) : super(key: key);

  @override
  State<FullPageSearch> createState() => _FullPageSearchState();
}

class _FullPageSearchState extends State<FullPageSearch> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant FullPageSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.forward();
    } else if (!widget.isActive && !_controller.isAnimating) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content (search bar always on top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: widget.searchBarHeight,
          child: widget.searchBar,
        ),
        // Full-screen overlay for search suggestions
        if (widget.isActive)
          Positioned(
            top: widget.searchBarHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.white,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: widget.suggestions,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
