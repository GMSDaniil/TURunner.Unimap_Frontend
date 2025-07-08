import 'package:flutter/material.dart';

class CategoryTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const CategoryTopBar({Key? key, required this.title, required this.onClose})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 5, 2, 35),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                splashRadius: 24,
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
