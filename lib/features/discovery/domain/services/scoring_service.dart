import 'dart:math';
import '/features/user/domain/models/user_full_profile.dart';
import '/features/user/domain/models/user_preferences.dart';
import '/features/user/domain/models/neuro_profile.dart';
import '/features/user/domain/models/user_interests.dart';

class ScoringService {
  // --- Dating Score (0-100) ---
  // Updated Weights based on Feedback:
  // Sensory: 25% (Critical for neurodivergent dating)
  // Intereses: 30% (User prioritized this)
  // Ritmo/comunicación: 25%
  // Intención: 15% (Less weight than compatibility)
  // Neuro (Social/Structure): 5%
  double calculateDatingScore(UserFullProfile a, UserFullProfile b) {
    if (a.datingPreferences == null || b.datingPreferences == null) return 0;
    
    double sensoryScore = _calculateSensoryScore(a.neuroProfile, b.neuroProfile) * 0.25; 
    double interestsScore = _calculateInterestsScore(a.interests, b.interests, isDating: true) * 0.30; 
    double rhythmScore = _calculateRhythmScore(a.neuroProfile, b.neuroProfile) * 0.25; 
    
    // Intention: Max 20 points raw. Normalize to 100 (x5) then weight 15% (0.15)
    double rawIntention = _calculateIntentionScore(a.datingPreferences!.intention, b.datingPreferences!.intention);
    double intentionScore = (rawIntention * 5) * 0.15; 

    double neuroScore = _calculateNeuroScore(a.neuroProfile, b.neuroProfile) * 0.05; 

    return sensoryScore + interestsScore + rhythmScore + intentionScore + neuroScore;
  }

  // --- Friendship Score (0-100) ---
  // Intereses: 35%
  // Ritmo/comunicación: 30%
  // Frecuencia/intensidad/modalidad: 20%
  // Sensorial: 10%
  // Aprendizaje: 5%
  double calculateFriendshipScore(UserFullProfile a, UserFullProfile b) {
    if (a.friendshipPreferences == null || b.friendshipPreferences == null) return 0;

    double interestsScore = _calculateInterestsScore(a.interests, b.interests, isDating: false) * 0.35; // Max 35
    double rhythmScore = _calculateRhythmScore(a.neuroProfile, b.neuroProfile) * 0.30; // Max 30
    double freqModeScore = _calculateFriendshipModeScore(a.friendshipPreferences!, b.friendshipPreferences!) * 0.20; // Max 20
    double sensoryScore = _calculateSensoryScore(a.neuroProfile, b.neuroProfile) * 0.10; // Max 10
    double learningScore = 2.5; // Placeholder (5% max)

    return interestsScore + rhythmScore + freqModeScore + sensoryScore + learningScore;
  }

  // Helper Calculations

  // Rhythm & Communication (Normalized 0-100)
  double _calculateRhythmScore(NeuroProfile a, NeuroProfile b) {
    // Compare response pace, communication methods, message volume
    // Simple implementation for now
    double score = 0;
    if (a.communication.responsePace == b.communication.responsePace) score += 40;
    else if ((a.communication.responsePace.index - b.communication.responsePace.index).abs() == 1) score += 20;

    if (a.communication.messageVolume == b.communication.messageVolume) score += 30;
    
    // Intersection of preferred methods
    var commonMethods = a.communication.preferredMethods.toSet().intersection(b.communication.preferredMethods.toSet());
    if (commonMethods.isNotEmpty) score += 30;

    return min(score, 100);
  }

  // Interests (Normalized 0-100)
  // Logic: Match (+), Neutral (0), Conflict (-)
  double _calculateInterestsScore(UserInterests a, UserInterests b, {required bool isDating}) {
    // Overlapping tags
    final setA = a.tagsNormalized.toSet();
    final setB = b.tagsNormalized.toSet();
    final intersection = setA.intersection(setB);
    
    // Simple ratio for now
    if (setA.isEmpty || setB.isEmpty) return 0;
    
    int denominator = max(1, min(setA.length, setB.length));
    double ratio = intersection.length / denominator; 
    return min(ratio * 100, 100);
  }

  // Intention (Returns 0-20 points directly)
  // 0 -> 20, 1 -> 16, 2 -> 12, 3 -> 6, 4 -> 2, 5 -> 0
  double _calculateIntentionScore(DatingIntention a, DatingIntention b) {
    int valA = _intentionToInt(a);
    int valB = _intentionToInt(b);
    int diff = (valA - valB).abs();
    
    switch (diff) {
      case 0: return 20;
      case 1: return 16;
      case 2: return 12;
      case 3: return 6;
      case 4: return 2;
      default: return 0;
    }
  }

  int _intentionToInt(DatingIntention i) {
    // Ladder:
    // pareja_estable = 5
    // pareja_estable_no_me_cierro = 4
    // ver_que_sale = 3
    // casual_no_me_cierro = 2
    // solo_casual = 1
    // solo_una_noche = 0
    switch (i) {
      case DatingIntention.pareja_estable: return 5;
      case DatingIntention.pareja_estable_no_me_cierro: return 4;
      case DatingIntention.ver_que_sale: return 3;
      case DatingIntention.casual_no_me_cierro: return 2;
      case DatingIntention.solo_casual: return 1;
      case DatingIntention.solo_una_noche: return 0;
    }
  }

  // Neuro (Normalized 0-100)
  double _calculateNeuroScore(NeuroProfile a, NeuroProfile b) {
    // Compatibility based on social battery match or complement?
    // Often similar needs match better.
    double score = 50; 
    if (a.social.socialBattery == b.social.socialBattery) score += 25;
    if (a.social.needForStructure == b.social.needForStructure) score += 25;
    return min(score, 100);
  }

  // Friendship Frequency/Mode (Normalized 0-100)
  double _calculateFriendshipModeScore(FriendshipPreferences a, FriendshipPreferences b) {
    double score = 0;
    // MeetMode: strict mismatch is hard filter, here scoring preference match
    if (a.meetMode == b.meetMode) score += 50;
    else if (a.meetMode == FriendshipMeetMode.flexible || b.meetMode == FriendshipMeetMode.flexible) score += 30;

    if (a.contactFrequency == b.contactFrequency) score += 50;
    else if ((a.contactFrequency.index - b.contactFrequency.index).abs() == 1) score += 25;

    return min(score, 100);
  }

  // Sensory (Normalized 0-100)
  double _calculateSensoryScore(NeuroProfile a, NeuroProfile b) {
    // Similar sensory needs often help
    double diff = (a.sensory.noiseTolerance - b.sensory.noiseTolerance).abs().toDouble() +
                  (a.sensory.crowdTolerance - b.sensory.crowdTolerance).abs().toDouble() +
                  (a.sensory.lightensitivity - b.sensory.lightensitivity).abs().toDouble(); // assuming sensitivity scale
    
    // Max diff for 3 scales of 1-5 (range 4) is 12.
    // 0 diff = 100 score. 12 diff = 0 score.
    double score = 100 - (diff / 12 * 100);
    return max(0, score);
  }
}
