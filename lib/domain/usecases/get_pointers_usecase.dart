
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/domain/repository/pointers.dart';
import 'package:auth_app/service_locator.dart';

class GetPointersUseCase {
  Future<List<Pointer>> call() async {
    return await sl<PointersRepository>().getPointers();
  }
}