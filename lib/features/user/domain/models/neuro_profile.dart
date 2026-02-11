
enum CommunicationMethod { text, audio, call, video, in_person }
enum ResponsePace { fast, medium, slow, whenever_can }
enum MessageVolume { high, medium, low }

class NeuroProfile {
  final CommunicationPreferences communication;
  final SensoryPreferences sensory;
  final SocialEnergy social;

  const NeuroProfile({
    this.communication = const CommunicationPreferences(),
    this.sensory = const SensoryPreferences(),
    this.social = const SocialEnergy(),
  });

  factory NeuroProfile.fromMap(Map<String, dynamic> map) {
    return NeuroProfile(
      communication: CommunicationPreferences.fromMap(map['communication'] ?? {}),
      sensory: SensoryPreferences.fromMap(map['sensory'] ?? {}),
      social: SocialEnergy.fromMap(map['social'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communication': communication.toMap(),
      'sensory': sensory.toMap(),
      'social': social.toMap(),
    };
  }
}

class CommunicationPreferences {
  final ResponsePace responsePace;
  final List<CommunicationMethod> preferredMethods;
  final MessageVolume messageVolume;

  const CommunicationPreferences({
    this.responsePace = ResponsePace.medium,
    this.preferredMethods = const [CommunicationMethod.text],
    this.messageVolume = MessageVolume.medium,
  });

  factory CommunicationPreferences.fromMap(Map<String, dynamic> map) {
    return CommunicationPreferences(
      responsePace: ResponsePace.values.firstWhere((e) => e.name == map['responsePace'], orElse: () => ResponsePace.medium),
      preferredMethods: (map['preferredMethods'] as List?)
          ?.map((e) => CommunicationMethod.values.firstWhere((v) => v.name == e, orElse: () => CommunicationMethod.text))
          .toList() ?? [CommunicationMethod.text],
      messageVolume: MessageVolume.values.firstWhere((e) => e.name == map['messageVolume'], orElse: () => MessageVolume.medium),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'responsePace': responsePace.name,
      'preferredMethods': preferredMethods.map((e) => e.name).toList(),
      'messageVolume': messageVolume.name,
    };
  }
}

class SensoryPreferences {
  final int noiseTolerance; // 1-5
  final int crowdTolerance; // 1-5
  final int lightensitivity; // 1-5

  const SensoryPreferences({
    this.noiseTolerance = 3,
    this.crowdTolerance = 3,
    this.lightensitivity = 3, // Let's call it sensitivity
  });

  factory SensoryPreferences.fromMap(Map<String, dynamic> map) {
    return SensoryPreferences(
      noiseTolerance: map['noiseTolerance'] ?? 3,
      crowdTolerance: map['crowdTolerance'] ?? 3,
      lightensitivity: map['lightensitivity'] ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noiseTolerance': noiseTolerance,
      'crowdTolerance': crowdTolerance,
      'lightensitivity': lightensitivity,
    };
  }
}

class SocialEnergy {
  final int socialBattery; // 1-5
  final int needForStructure; // 1-5

  const SocialEnergy({
    this.socialBattery = 3,
    this.needForStructure = 3,
  });

  factory SocialEnergy.fromMap(Map<String, dynamic> map) {
    return SocialEnergy(
      socialBattery: map['socialBattery'] ?? 3,
      needForStructure: map['needForStructure'] ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'socialBattery': socialBattery,
      'needForStructure': needForStructure,
    };
  }
}
