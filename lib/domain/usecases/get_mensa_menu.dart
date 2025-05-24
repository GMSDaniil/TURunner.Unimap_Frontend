import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/meal_model.dart';
import '../repository/mensa.dart';
import '../../service_locator.dart';

class GetMensaMenuUseCase {
  Future<List<MealModel>> call(GetMenuReqParams params) async {
    return await sl<MensaRepository>().getMensaMenu(params);
  }
}
