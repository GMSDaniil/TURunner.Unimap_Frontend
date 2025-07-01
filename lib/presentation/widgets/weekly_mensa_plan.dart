import 'package:flutter/material.dart';
import 'package:auth_app/data/models/mensa_menu_response.dart';

/// Expects an already loaded [menu] as a parameter.
class WeeklyMensaPlan extends StatefulWidget {
  final MensaMenuResponse menu;
  final ScrollController? scrollController;

  const WeeklyMensaPlan({Key? key, required this.menu, this.scrollController})
    : super(key: key);

  @override
  State<WeeklyMensaPlan> createState() => _WeeklyMensaPlanState();
}

class _WeeklyMensaPlanState extends State<WeeklyMensaPlan> {
  int selectedDayIndex = 0;
  static const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const weekdayNames = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday;
    // If today is saturday or sonnday, we set the selected day to friday
    // otherwise set it to the previous day (Mon-Fri)
    selectedDayIndex = today >= 6 ? 4 : today - 1;
  }

  @override
  Widget build(BuildContext context) {
    final response = widget.menu;

    if (response.days.isEmpty) {
      return const Center(child: Text("No menu available."));
    }

    //menu for the selected day
    final selectedDayName = weekdayNames[selectedDayIndex];
    final selectedMenu = response.days.firstWhere(
      (d) => d.dayName.toLowerCase() == selectedDayName.toLowerCase(),
      orElse: () => MensaDayMenu(dayName: '', isAvailable: false, groups: {}),
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Title
            const Text(
              "Weekly Canteen Plan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            // Weekday selector bar
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(weekdayLabels.length, (i) {
                  final isSelected = i == selectedDayIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDayIndex = i;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4CAF50).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              weekdayLabels[i],
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF4CAF50)
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            if (!selectedMenu.isAvailable || selectedMenu.groups.isEmpty)
              const Center(
                child: Text(
                  "No menu for today.",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              )
            else
              Expanded(
                child: ListView(
                  controller: widget.scrollController,
                  children: selectedMenu.groups.entries.expand((entry) {
                    final groupName = entry.key;
                    final dishes = entry.value;
                    return [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                        child: Text(
                          groupName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      ...dishes.map<Widget>(
                        (dish) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(dish.name),
                          subtitle: dish.price.isNotEmpty
                              ? Text('Price: ${dish.price}')
                              : null,
                          trailing: dish.vegan
                              ? const Icon(Icons.eco, color: Colors.green)
                              : dish.vegetarian
                              ? const Icon(Icons.spa, color: Colors.orange)
                              : null,
                        ),
                      ),
                    ];
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
