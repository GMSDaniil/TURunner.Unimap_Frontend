
import 'package:auth_app/data/models/pointer.dart';

abstract class PointersRepository {
  Future<List<Pointer>> getPointers();
}