import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/meal_model.dart';


abstract class MensaRepository {
  Future<List<MealModel>> getMensaMenu(GetMenuReqParams mensaName);
}
