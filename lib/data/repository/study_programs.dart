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
          final programs = (response.data as List)
              .map((json) => StudyProgramEntity.fromJson(json))
              .toList();
          
          return Right(programs);
        } catch (e) {
          return Left('Failed to parse study programs');
        }
      },
    );
  }
}