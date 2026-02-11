
class SecondChanceModel {
  final String uid; // The profile to reconsider
  final DateTime expiresAt;

  SecondChanceModel({
    required this.uid,
    required this.expiresAt,
  });
}
