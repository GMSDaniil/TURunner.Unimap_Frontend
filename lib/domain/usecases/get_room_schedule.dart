import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/data/source/room_schedule_api_service.dart';
import 'package:auth_app/data/models/room_schedule_response.dart';
import 'package:auth_app/data/models/get_room_schedule_params.dart';
import 'package:dartz/dartz.dart';

class GetRoomScheduleUseCase 
    implements UseCase<Either<String, RoomScheduleResponse>, GetRoomScheduleParams> {
  final RoomScheduleApiService _roomScheduleApiService;

  GetRoomScheduleUseCase(this._roomScheduleApiService);

  @override
  Future<Either<String, RoomScheduleResponse>> call({GetRoomScheduleParams? param}) async {
    if (param == null) return Left("Parameters can not be null");
    
    final result = await _roomScheduleApiService.getRoomSchedule(param.roomId, param.date);
    
    return result.fold(
      (error) => Left(error),
      (response) => Right(RoomScheduleResponse.fromJson(response.data)),
    );
  }
}