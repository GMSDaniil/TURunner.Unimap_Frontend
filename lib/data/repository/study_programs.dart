import 'dart:convert';
import 'package:auth_app/domain/entities/study_program.dart';
import 'package:auth_app/domain/repository/study_programs.dart';
import 'package:auth_app/data/source/study_programs_api_service.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class StudyProgramsRepositoryImpl implements StudyProgramsRepository {
  @override
  Future<Either<String, List<StudyProgramEntity>>> getStudyPrograms() async {
    final result = await sl<StudyProgramsApiService>().getStudyPrograms();

    return result.fold(
      (errorMessage) => Left(errorMessage),
      (response) {
        try {
          // Handle the backend format: { [ { "name": "...", "id": 24524 }, ... ] }
          dynamic data = response.data;
          
          // If data is string, decode it
          if (data is String) {
            data = jsonDecode(data);
          }
          
          print('📊 Raw response data: $data');
          print('📊 Data type: ${data.runtimeType}');
          
          List<dynamic> programsList;
          
          // Backend returns direct array: [ { "name": "...", "id": 24524 }, ... ]
          if (data is List) {
            programsList = data;
          } 
          // Or it might be wrapped: { "programs": [...] } or { "data": [...] }
          else if (data is Map<String, dynamic>) {
            if (data.containsKey('data')) {
              programsList = data['data'] as List<dynamic>;
            } else if (data.containsKey('programs')) {
              programsList = data['programs'] as List<dynamic>;
            } else if (data.containsKey('study_programs')) {
              programsList = data['study_programs'] as List<dynamic>;
            } else {
              return Left('Invalid response structure: expected array or object with data field');
            }
          } else {
            return Left('Invalid response format: expected array or object');
          }
          
          print('📊 Programs list: $programsList');
          print('📊 Programs count: ${programsList.length}');
          
          final studyPrograms = <StudyProgramEntity>[];
          
          for (int i = 0; i < programsList.length; i++) {
            try {
              final item = programsList[i];
              
              if (item is! Map<String, dynamic>) {
                print('⚠️ Skipping invalid item at index $i: not a map');
                continue;
              }
              
              // Backend format uses "name" and "id" (not "stupo_number")
              final name = item['name']?.toString();
              final id = item['id']?.toString(); // Convert to string for consistency
              
              if (name == null || id == null) {
                print('⚠️ Skipping item at index $i: missing name or id');
                continue;
              }
              
              studyPrograms.add(StudyProgramEntity(
                name: name,
                stupoNumber: id, // Use "id" as stupo number
              ));
              
              print('✅ Added: $name → $id');
              
            } catch (e) {
              print('❌ Error processing item at index $i: $e');
              continue;
            }
          }
          
          print('✅ Successfully parsed ${studyPrograms.length} study programs');
          return Right(studyPrograms);
          
        } catch (e) {
          print('❌ Error parsing study programs: $e');
          return Left('Failed to parse study programs: ${e.toString()}');
        }
      },
    );
  }
}