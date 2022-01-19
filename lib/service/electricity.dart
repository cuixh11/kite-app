import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

part 'electricity.g.dart';

enum _Mode {
  balance,
  rank,
  condition_hours,
  condition_days,
}

String _getElectricityUrl(String room, _Mode mode) {
  switch (mode) {
    case _Mode.balance:
      return 'https://kite.sunnysab.cn/api/v2/electricity/room/$room';
    case _Mode.rank:
      return 'https://kite.sunnysab.cn/api/v2/electricity/room/$room/rank';
    case _Mode.condition_hours:
      return 'https://kite.sunnysab.cn/api/v2/electricity/room/$room/bill/hours';
    case _Mode.condition_days:
      return 'https://kite.sunnysab.cn/api/v2/electricity/room/$room/bill/days';
  }
}

@JsonSerializable()
class Balance {
  double balance;
  double power;
  String ts;

  Balance(this.balance, this.power, this.ts);

  factory Balance.fromJson(Map<String, dynamic> json) =>
      _$BalanceFromJson(json);
}

@JsonSerializable()
class Rank {
  double consumption;
  int rank;
  int roomCount;

  Rank(this.consumption, this.rank, this.roomCount);

  factory Rank.fromJson(Map<String, dynamic> json) =>
      _$RankFromJson(json);
}

@JsonSerializable()
class ConditionHours {
  double charge;
  double consumption;
  String time;

  ConditionHours(this.charge, this.consumption, this.time);

  factory ConditionHours.fromJson(Map<String, dynamic> json) =>
      _$ConditionHoursFromJson(json);
}

Future<Balance> getBalance(String room) async {
  final url = _getElectricityUrl(room, _Mode.balance);
  final response = await Dio().get(url);
  final balance = Balance.fromJson(response.data['data']);

  return balance;
}

Future<Rank> getRank(String room) async {
  final url = _getElectricityUrl(room, _Mode.rank);
  final response = await Dio().get(url);
  final rank = Rank.fromJson(response.data['data']);

  return rank;
}

Future<ConditionHours> getConditionHours(String room) async {
  final url = _getElectricityUrl(room, _Mode.condition_hours);
  final response = await Dio().get(url);
  final conditionHours = ConditionHours.fromJson(response.data['data']);

  return conditionHours;
}
