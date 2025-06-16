import 'package:flutter/material.dart';

class SearchOverlay extends StatefulWidget {
  final Widget child;

  const SearchOverlay({Key? key, required this.child}) : super(key: key);

  @override
  _SearchOverlayState createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  bool _isVisible = false;

  void show() => setState(() => _isVisible = true);
  void hide() => setState(() => _isVisible = false);

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    return Positioned(
      // This overlay will appear near the top (adjust as needed)
      top: 0,
      left: 0,
      right: 0,
      child: widget.child,
    );
  }
}