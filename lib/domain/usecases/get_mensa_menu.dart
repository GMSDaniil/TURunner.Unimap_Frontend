import '../entities/meal.dart';
import '../repository/mensa.dart';

class GetMensaMenuUseCase {
  final MensaRepository repository;

  GetMensaMenuUseCase(this.repository);

  Future<List<MealEntity>> call(String mensaName) async {
    return await repository.getMensaMenu(mensaName);
  }
}
