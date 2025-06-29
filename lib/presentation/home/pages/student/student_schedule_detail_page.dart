import 'package:auth_app/domain/entities/student_schedule.dart';
import 'package:flutter/material.dart';
import 'package:auth_app/data/models/student_schedule_response.dart';

class StudentScheduleDetailPage extends StatelessWidget {
  final List<StudentLectureEntity> lectures;

  const StudentScheduleDetailPage({
    super.key,
    required this.lectures,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Schedule (${lectures.length} lectures)'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF9C27B0), // Purple
                Color(0xFFEF4136), // Red
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lectures.length,
        itemBuilder: (context, index) {
          final lecture = lectures[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF9C27B0),
                child: Text(
                  lecture.courseName.isNotEmpty 
                      ? lecture.courseName[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                lecture.courseName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lecture.instructor.isNotEmpty)
                    Text('👨‍🏫 ${lecture.instructor}'),
                  if (lecture.location.isNotEmpty)
                    Text('📍 ${lecture.location}'),
                  if (lecture.timeSchedule.isNotEmpty)
                    Text('🕒 ${lecture.timeSchedule}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLectureDetails(context, lecture),
            ),
          );
        },
      ),
    );
  }

  void _showLectureDetails(BuildContext context, StudentLectureEntity lecture) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lecture.courseName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Instructor', lecture.instructor),
            _buildDetailRow('Location', lecture.location),
            _buildDetailRow('Time', lecture.timeSchedule),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}