import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/mensa_menu_response.dart';
import 'package:auth_app/domain/repository/mensa.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class GetMensaMenuUseCase
    implements UseCase<Either<String, MensaMenuResponse>, GetMenuReqParams> {
  String _mapUiNameToApiName(String name) {
    final n = name.toLowerCase();
    if (n.contains('veggie')) return 'veggie';
    if (n.contains('march')) return 'marchstrasse';
    if (n.contains('hardenberg')) return 'hardenbergstrasse';
    return 'hardenbergstrasse';
  }

  @override
  Future<Either<String, MensaMenuResponse>> call({
    GetMenuReqParams? param,
  }) async {
    if (param == null) return Left("Parameters can not be null");
    try {
      final repo = sl<MensaRepository>();
      // Mapping
      final mappedParam = GetMenuReqParams(
        mensaName: _mapUiNameToApiName(param.mensaName),
      );
      final result = await repo.getMensaMenu(mappedParam);
      //print('GetMensaMenuUseCase result: $result');
      return result;
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}

/*
class GetMensaMenuUseCase {
  Future<List<MealModel>> call(GetMenuReqParams params) async {
    return await sl<MensaRepository>().getMensaMenu(params);
  }
}
*/
