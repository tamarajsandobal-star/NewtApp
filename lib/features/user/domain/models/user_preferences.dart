
enum Gender { mujer, hombre, no_binario, otro } // For user's own gender
enum GenderInterest { mujeres, hombres, no_binario_otres, sin_preferencia }

enum RelationalStructure { monogamia, poliamor, no_monogamia }
enum DatingIntention {
  pareja_estable,
  pareja_estable_no_me_cierro,
  ver_que_sale,
  casual_no_me_cierro,
  solo_casual,
  solo_una_noche
}

enum FriendshipMeetMode { solo_virtual, solo_presencial, flexible }
enum ContactFrequency { baja, media, alta, flexible }

class AgeRange {
  final int min;
  final int max;

  const AgeRange({required this.min, required this.max});
}

class DatingPreferences {
  final List<GenderInterest> genderInterest;
  final AgeRange ageRange;
  final int distanceMaxKm;
  final RelationalStructure relationalStructure;
  final DatingIntention intention;

  DatingPreferences({
    required this.genderInterest,
    required this.ageRange,
    required this.distanceMaxKm,
    required this.relationalStructure,
    required this.intention,
  });

  factory DatingPreferences.fromMap(Map<String, dynamic> map) {
    return DatingPreferences(
      genderInterest: (map['genderInterest'] as List?)
          ?.map((e) => GenderInterest.values.firstWhere((v) => v.name == e, orElse: () => GenderInterest.sin_preferencia))
          .toList() ?? [],
      ageRange: AgeRange(
        min: map['ageRange']?['min'] ?? 18,
        max: map['ageRange']?['max'] ?? 99,
      ),
      distanceMaxKm: map['distanceMaxKm'] ?? 50,
      relationalStructure: RelationalStructure.values.firstWhere(
        (e) => e.name == map['relationalStructure'], 
        orElse: () => RelationalStructure.monogamia
      ),
      intention: DatingIntention.values.firstWhere(
        (e) => e.name == map['intention'],
        orElse: () => DatingIntention.ver_que_sale
      ),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'genderInterest': genderInterest.map((e) => e.name).toList(),
      'ageRange': {'min': ageRange.min, 'max': ageRange.max},
      'distanceMaxKm': distanceMaxKm,
      'relationalStructure': relationalStructure.name,
      'intention': intention.name,
    };
  }
}

class FriendshipPreferences {
  final List<GenderInterest> genderInterest;
  final AgeRange ageRange;
  final int distanceMaxKm;
  final List<String> friendshipStyle; // "charlar", "gaming", etc.
  final FriendshipMeetMode meetMode;
  final ContactFrequency contactFrequency;

  FriendshipPreferences({
    required this.genderInterest,
    required this.ageRange,
    required this.distanceMaxKm,
    required this.friendshipStyle,
    required this.meetMode,
    required this.contactFrequency,
  });

  factory FriendshipPreferences.fromMap(Map<String, dynamic> map) {
    return FriendshipPreferences(
      genderInterest: (map['genderInterest'] as List?)
          ?.map((e) => GenderInterest.values.firstWhere((v) => v.name == e, orElse: () => GenderInterest.sin_preferencia))
          .toList() ?? [],
      ageRange: AgeRange(
        min: map['ageRange']?['min'] ?? 18,
        max: map['ageRange']?['max'] ?? 99,
      ),
      distanceMaxKm: map['distanceMaxKm'] ?? 50,
      friendshipStyle: List<String>.from(map['friendshipStyle'] ?? []),
      meetMode: FriendshipMeetMode.values.firstWhere(
        (e) => e.name == map['meetMode'],
        orElse: () => FriendshipMeetMode.flexible
      ),
      contactFrequency: ContactFrequency.values.firstWhere(
        (e) => e.name == map['contactFrequency'],
        orElse: () => ContactFrequency.flexible
      ),
    );
  }

  Map<String, dynamic> toMap() {
     return {
      'genderInterest': genderInterest.map((e) => e.name).toList(),
      'ageRange': {'min': ageRange.min, 'max': ageRange.max},
      'distanceMaxKm': distanceMaxKm,
      'friendshipStyle': friendshipStyle,
      'meetMode': meetMode.name,
      'contactFrequency': contactFrequency.name,
    };
  }
}
