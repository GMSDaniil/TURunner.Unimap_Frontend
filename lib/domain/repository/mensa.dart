import '../entities/meal.dart';

abstract class MensaRepository {
  Future<List<MealEntity>> getMensaMenu(String mensaName);
}
