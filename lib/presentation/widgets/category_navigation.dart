import 'package:flutter/material.dart';

class CategoryNavigationBar extends StatefulWidget {
  // allow nullable params
  final void Function(String? category, Color? color) onCategorySelected;

  const CategoryNavigationBar({
    Key? key,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategoryNavigationBar> createState() => _CategoryNavigationBarState();
}

class _CategoryNavigationBarState extends State<CategoryNavigationBar> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildChip(
                  icon: Icons.local_cafe,
                  label: 'Cafe',
                  color: Colors.orange,
                ),
                _buildChip(
                  icon: Icons.local_library,
                  label: 'Library',
                  color: Colors.yellow[800]!,
                ),
                _buildChip(
                  icon: Icons.restaurant,
                  label: 'Mensa',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected ? color.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              _selectedCategory = isSelected ? null : label;
            });
            // pass nulls when unselected
            widget.onCategorySelected(
              _selectedCategory,
              _selectedCategory != null ? color : null,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
