import '/core/enums/app_enums.dart';

class MatchModel {
  final String id;
  final List<String> participants;
  final DateTime createdAt;
  final AppMode mode;
  final Map<String, bool> users; // For querying: {'uid1': true, 'uid2': true}

  MatchModel({
    required this.id,
    required this.participants,
    required this.createdAt,
    required this.mode,
    required this.users,
  });
}
