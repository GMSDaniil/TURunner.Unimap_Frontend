import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:auth_app/presentation/home/pages/room_schedule.dart';
import 'package:auth_app/domain/usecases/get_room_schedule.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:auth_app/data/models/room_schedule_response.dart';
import 'package:auth_app/data/models/get_room_schedule_params.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SlidingUpPanel(
          panel: const RoomsListPanel(),
          body: Center(
            child: Text("Основной контент"),
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          minHeight: 100,
          maxHeight: 850,
        ),
      ),
    );
  }
}


class RoomsListPanel extends StatelessWidget {
  final String? buildingName;
  final List<String>? rooms;

  const RoomsListPanel({
    super.key, 
    this.buildingName,
    this.rooms,
  });

  // Helper method to convert API events to the format expected by ScheduleWidget
  Map<String, List<Map<String, String>>> _convertApiEventsToWeeklyEvents(List<RoomEvent> events) {
    final Map<String, List<Map<String, String>>> weeklyEvents = {};
    
    for (final event in events) {
      final parts = event.datetime.split(', ');
      final day = parts[0].split('. ')[0];
      final time = parts[1].split(' - ')[0].substring(0, 5);
      
      final dayMap = {
        'Mo': 'Понедельник',
        'Di': 'Вторник',
        'Mi': 'Среда',
        'Do': 'Четверг',
        'Fr': 'Пятница',
      };
      
      final dayName = dayMap[day] ?? 'Понедельник';
      final hour = int.parse(time.split(':')[0]);
      final slot = '${hour}-${hour + 2}';
      
      weeklyEvents[dayName] ??= [];
      weeklyEvents[dayName]!.add({
        'time': slot,
        'title': event.title,
        'lecturer': event.lecturer,
      });
    }
    
    return weeklyEvents;
  }

  @override
  Widget build(BuildContext context) {
    final displayRooms = rooms ?? [];
    final displayName = buildingName ?? "Building";

    return Column(
      children: [
        // Полоска сверху
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // Название здания
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Количество комнат
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            '${displayRooms.length} rooms available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),

        // Список комнат
        Expanded(
          child: displayRooms.isEmpty
              ? Center(
                  child: Text(
                    'No rooms available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(), // Add this line
                  itemCount: displayRooms.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.meeting_room),
                      title: Text(displayRooms[index]),
                      onTap: () async {
                        try {
                          final result = await sl<GetRoomScheduleUseCase>().call(
                            param: GetRoomScheduleParams(
                              roomId: displayRooms[index],
                              date: DateTime.now().toString().split(' ')[0], // Format: YYYY-MM-DD
                            ),
                          );

                          if (!context.mounted) return;

                          result.fold(
                            (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $error')),
                              );
                            },
                            (response) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScheduleWidget(
                                    roomName: displayRooms[index],
                                    weeklyEvents: _convertApiEventsToWeeklyEvents(response.events),
                                  ),
                                ),
                              );
                            },
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Unexpected error: $e')),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
