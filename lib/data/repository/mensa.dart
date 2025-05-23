import '../../domain/entities/meal.dart';
import '../../domain/repository/mensa.dart';
import '../source/mensa_api_service.dart';

class MensaRepositoryImpl implements MensaRepository {
  final MensaApiService apiService;

  MensaRepositoryImpl(this.apiService);

  @override
  Future<List<MealEntity>> getMensaMenu(String mensaName) {
    return apiService.fetchMensaMeals(mensaName);
  }
}
