import 'package:auth_app/domain/entities/study_program.dart';
import 'package:auth_app/domain/repository/student.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class GetStudyProgramsUseCase
    implements UseCase<Either<String, List<StudyProgramEntity>>, void> {
  @override
  Future<Either<String, List<StudyProgramEntity>>> call({void param}) async {
    try {
      return await sl<StudentRepository>().getStudyPrograms();
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}