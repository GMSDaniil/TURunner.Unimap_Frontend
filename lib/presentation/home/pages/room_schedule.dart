import 'package:flutter/material.dart';

class ScheduleWidget extends StatefulWidget {
  final String roomName;
  final Map<String, List<Map<String, String>>> weeklyEvents;

  const ScheduleWidget({
    super.key,
    required this.roomName,
    required this.weeklyEvents,
  });

  @override
  State<ScheduleWidget> createState() => _ScheduleWidgetState();
}

class _ScheduleWidgetState extends State<ScheduleWidget> {
  int selectedDayIndex = 0;
  List<DateTime> weekDates = [];
  static const weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri"];
  static const weekdayNames = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница"];
  static const timeSlots = ["8-10", "10-12", "12-14", "14-16", "16-18", "18-20"];

  @override
  void initState() {
    super.initState();
    _calculateWeekDates();
  }

  void _calculateWeekDates() {
    final now = DateTime.now();
    final mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    weekDates = List.generate(5, (index) => mondayOfWeek.add(Duration(days: index)));
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}";
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: weekDates.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Schedule — ${widget.roomName}"),
          bottom: TabBar(
            tabs: List.generate(weekDates.length, (index) {
              final date = weekDates[index];
              final isToday = _isToday(date);
              return Tab(
                child: Column(
                  children: [
                    Text(weekdayLabels[index]),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        color: isToday ? Colors.orange : null,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        body: widget.weeklyEvents.isEmpty
            ? const Center(
                child: Text(
                  "No schedule available for this room",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
            : TabBarView(
                children: List.generate(weekDates.length, (i) {
                  final date = weekDates[i];
                  final dayEvents = widget.weeklyEvents[weekdayNames[i]] ?? [];

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: double.infinity, // растягиваем таблицу на всю ширину
                      child: DataTable(
                        columnSpacing: 24, // расстояние между столбцами
                        columns: const [
                          DataColumn(
                            label: SizedBox(
                              width: 100, // ширина столбца "Время"
                              child: Text(
                                "Time",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 250, // ширина столбца "Мероприятие"
                              child: Text(
                                "Event",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                        rows: List.generate(timeSlots.length, (index) {
                          final slot = timeSlots[index];
                          final event = dayEvents.firstWhere(
                            (e) => e["time"] == slot,
                            orElse: () => {},
                          );
                          final title = event["title"] ?? "";
                          return DataRow(cells: [
                            DataCell(Text(slot)),
                            DataCell(Text(title)),
                          ]);
                        }),
                      ),
                    ),
                  );
                }),
              ),
      ),
    );
  }
}
