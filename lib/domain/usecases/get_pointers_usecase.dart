
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/domain/repository/pointers.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class GetPointersUseCase implements UseCase<Either<String, List<Pointer>>, dynamic> {
  @override
  Future<Either<String, List<Pointer>>> call({dynamic param}) async {
    try {
      return await sl<PointersRepository>().getPointers();
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}