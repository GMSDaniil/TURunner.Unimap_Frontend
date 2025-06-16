```dart
import 'package:flutter/material.dart';
import 'bottom_navigation_l.dart';

class MainScreen extends StatefulWidget {
  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  bool _isNavBarVisible = true;

  void _onSearchPressed() {
    setState(() {
      _isNavBarVisible = false;
    });
    // ...existing code for search...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...existing code...
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isNavBarVisible
            ? BottomNavigationL(key: ValueKey('nav'), isVisible: true)
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
      // ...existing code...
      floatingActionButton: FloatingActionButton(
        onPressed: _onSearchPressed,
        // ...existing code...
      ),
      // ...existing code...
    );
  }
}
```