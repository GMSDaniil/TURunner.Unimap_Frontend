import 'package:auth_app/domain/entities/study_program.dart';
import 'package:dartz/dartz.dart';

abstract class StudyProgramsRepository {
  Future<Either<String, List<StudyProgramEntity>>> getStudyPrograms();
}