import 'package:flutter/material.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/domain/usecases/get_mensa_menu.dart';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/mensa_menu_response.dart';
import 'package:dartz/dartz.dart' hide State;

class WeeklyMensaPlan extends StatefulWidget {
  final String mensaName;

  const WeeklyMensaPlan({Key? key, required this.mensaName}) : super(key: key);

  @override
  State<WeeklyMensaPlan> createState() => _WeeklyMensaPlanState();
}

class _WeeklyMensaPlanState extends State<WeeklyMensaPlan> {
  int selectedDayIndex = 0;

  static const weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun', // Add Sunday to the list
  ];
  static const weekdayNames = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday", // Add Sunday to the list
  ];

  @override
  void initState() {
    super.initState();
    selectedDayIndex = DateTime.now().weekday - 1;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<String, MensaMenuResponse>>(
      future: sl<GetMensaMenuUseCase>().call(
        param: GetMenuReqParams(mensaName: widget.mensaName),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isLeft()) {
          return const Text("No menu available.");
        }

        final response = snapshot.data!.getOrElse(
          () => MensaMenuResponse(mensaName: '', days: []),
        );
        if (response.days.isEmpty) {
          return const Text("No menu available.");
        }

        // Find the menu for the selected day
        final selectedDayName = weekdayNames[selectedDayIndex];
        final selectedMenu = response.days.firstWhere(
          (d) => d.dayName.toLowerCase() == selectedDayName.toLowerCase(),
          orElse: () =>
              MensaDayMenu(dayName: '', isAvailable: false, groups: {}),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Weekly Mensa Plan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Weekday selector bar
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(weekdayLabels.length, (i) { // Use full length
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
            const SizedBox(height: 12),

            // Show menu or closed message
            if (selectedDayIndex >= 5)
              const Center(
                child: Text(
                  "Closed today",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              )
            else if (!selectedMenu.isAvailable || selectedMenu.groups.isEmpty)
              const Center(
                child: Text(
                  "No menu for today.",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView(
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
                            fontSize: 14,
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
        );
      },
    );
  }
}
