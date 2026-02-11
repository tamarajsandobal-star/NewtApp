import '/features/user/domain/models/user_full_profile.dart';
import '/features/user/domain/models/user_preferences.dart';
import 'scoring_service.dart';
import 'dart:math';

class DiscoveryCandidate {
  final UserFullProfile profile;
  final double score;

  DiscoveryCandidate({required this.profile, required this.score});
}

class DiscoveryService {
  final ScoringService _scoringService;

  DiscoveryService(this._scoringService);

  final List<String> _debugLogs = [];
  List<String> get lastDebugLogs => List.unmodifiable(_debugLogs);

  // --- Dating Discovery ---
  Future<List<DiscoveryCandidate>> getDatingCandidates({
    required UserFullProfile currentUser,
    required List<UserFullProfile> allCandidates,
    required Set<String> blockedUserIds,
    required Set<String> alreadyInteractedUserIds,
  }) async {
    if (currentUser.datingPreferences == null || !currentUser.user.settings.datingActive) {
      return [];
    }

    _debugLogs.clear();
    _debugLogs.add("Starting Dating Discovery for ${currentUser.user.uid} (${currentUser.user.displayName})");
    _debugLogs.add("Candidates found: ${allCandidates.length}");

    final prefs = currentUser.datingPreferences!;
    
    // 1. Hard Filters
    var filtered = allCandidates.where((candidate) {
      if (candidate.user.uid == currentUser.user.uid) return false;
      if (blockedUserIds.contains(candidate.user.uid)) {
          _debugLogs.add("Dropped ${candidate.user.displayName}: Blocked");
          return false;
      }
      if (alreadyInteractedUserIds.contains(candidate.user.uid)) {
          // Silent drop for swipes
          return false;
      }
      if (candidate.datingPreferences == null) {
          _debugLogs.add("Dropped ${candidate.user.displayName}: No Dating Prefs");
          return false;
      }
      if (!candidate.user.settings.datingActive) {
          _debugLogs.add("Dropped ${candidate.user.displayName}: Dating Not Active");
          return false;
      }

      // 2. Age Check (Reciprocal)
      if (candidate.user.birthDate != null && currentUser.user.birthDate != null) {
          int candidateAge = DateTime.now().year - candidate.user.birthDate!.year; 
          int myAge = DateTime.now().year - currentUser.user.birthDate!.year;

          // Check if THEY fit MY range
          if (candidateAge < prefs.ageRange.min || candidateAge > prefs.ageRange.max) {
             _debugLogs.add("Dropped ${candidate.user.displayName}: Age mismatch (Their age $candidateAge not in My Range ${prefs.ageRange.min}-${prefs.ageRange.max})");
             return false;
          }
          // Check if I fit THEIR range (Reciprocal)
          if (candidate.datingPreferences != null) {
              final theirRange = candidate.datingPreferences!.ageRange;
              if (myAge < theirRange.min || myAge > theirRange.max) {
                  _debugLogs.add("Dropped ${candidate.user.displayName}: Reciprocal Age mismatch (My age $myAge not in Their Range ${theirRange.min}-${theirRange.max})");
                  return false;
              }
          }
      }

      // 3. Distance Check (Reciprocal)
      if (currentUser.user.location != null && candidate.user.location != null) {
          double dist = _calculateDistance(currentUser.user.location!, candidate.user.location!);
          
          // Me -> Them
          if (dist > prefs.distanceMaxKm) {
              _debugLogs.add("Dropped ${candidate.user.displayName}: Distance mismatch ($dist km > My Max ${prefs.distanceMaxKm})");
              return false;
          }
          // Them -> Me (Reciprocal)
          if (candidate.datingPreferences != null) {
              if (dist > candidate.datingPreferences!.distanceMaxKm) {
                  _debugLogs.add("Dropped ${candidate.user.displayName}: Reciprocal Distance mismatch ($dist km > Their Max ${candidate.datingPreferences!.distanceMaxKm})");
                  return false;
              }
          }
      }

      // Monogamy vs Non-Monogamy Hard Filter
      if (!_isMonogamyCompatible(prefs.relationalStructure, candidate.datingPreferences!.relationalStructure)) {
         _debugLogs.add("Dropped ${candidate.user.displayName}: Structure mismatch (${candidate.datingPreferences!.relationalStructure.name} vs ${prefs.relationalStructure.name})");
         return false;
      }

      // Gender Filter (Me -> Them)
      if (!_isGenderCompatible(prefs.genderInterest, candidate.user.gender)) {
         _debugLogs.add("Dropped ${candidate.user.displayName}: Gender mismatch (My Prefs: ${prefs.genderInterest}, Their Gender: ${candidate.user.gender})");
         return false;
      }

      // Gender Filter (Them -> Me) - RECIPROCAL
      if (!_isGenderCompatible(candidate.datingPreferences!.genderInterest, currentUser.user.gender)) {
         _debugLogs.add("Dropped ${candidate.user.displayName}: Reciprocal Gender mismatch (Their Prefs: ${candidate.datingPreferences!.genderInterest}, My Gender: ${currentUser.user.gender})");
         return false;
      }

      // Hide Unverified Candidates (if viewer is verified? No, general rule)
      if (!candidate.user.isVerified) {
         _debugLogs.add("Dropped ${candidate.user.displayName}: Not Verified");
         return false;
      }

      return true;
    }).toList();

    // 2. Scoring
    List<DiscoveryCandidate> candidates = filtered.map((candidate) {
        double score = _scoringService.calculateDatingScore(currentUser, candidate);
        return DiscoveryCandidate(profile: candidate, score: score);
    }).toList();

    // 3. Sorting
    candidates.sort((a, b) => b.score.compareTo(a.score));

    return candidates;
  }

  // --- Friendship Discovery ---
  Future<List<DiscoveryCandidate>> getFriendshipCandidates({
    required UserFullProfile currentUser,
    required List<UserFullProfile> allCandidates,
    required Set<String> blockedUserIds,
    required Set<String> alreadyInteractedUserIds,
  }) async {
    if (currentUser.friendshipPreferences == null || !currentUser.user.settings.friendsActive) {
      return [];
    }
    
    _debugLogs.clear();
    _debugLogs.add("Starting Friendship Discovery for ${currentUser.user.uid}");

    final prefs = currentUser.friendshipPreferences!;

    var filtered = allCandidates.where((candidate) {
      if (candidate.user.uid == currentUser.user.uid) return false;
      if (blockedUserIds.contains(candidate.user.uid)) return false;
      if (alreadyInteractedUserIds.contains(candidate.user.uid)) return false;
      if (candidate.friendshipPreferences == null || !candidate.user.settings.friendsActive) return false;

      // MeetMode Hard Filter
      if (!_isMeetModeCompatible(prefs.meetMode, candidate.friendshipPreferences!.meetMode)) {
        return false;
      }
      
      // Gender Filter (Friendship) - Me -> Them
      if (!_isGenderCompatible(prefs.genderInterest, candidate.user.gender)) {
         return false;
      }
      // Gender Filter (Friendship) - Them -> Me
      if (!_isGenderCompatible(candidate.friendshipPreferences!.genderInterest, currentUser.user.gender)) {
         return false;
      }
      
      // Hide Unverified Candidates
      if (!candidate.user.isVerified) return false;

      return true;
    }).toList();

    List<DiscoveryCandidate> candidates = filtered.map((candidate) {
        double score = _scoringService.calculateFriendshipScore(currentUser, candidate);
        return DiscoveryCandidate(profile: candidate, score: score);
    }).toList();

    candidates.sort((a, b) => b.score.compareTo(a.score));

    return candidates;
  }

  bool _isMonogamyCompatible(RelationalStructure a, RelationalStructure b) {
    // User requested strict filtering:
    // Monogamy sees Monogamy
    // Polyamory sees Polyamory
    // Non-monogamy sees Non-monogamy
    return a == b; 
  }

  bool _isMeetModeCompatible(FriendshipMeetMode a, FriendshipMeetMode b) {
    if (a == FriendshipMeetMode.flexible || b == FriendshipMeetMode.flexible) return true;
    if (a == FriendshipMeetMode.solo_virtual && b == FriendshipMeetMode.solo_presencial) return false;
    if (a == FriendshipMeetMode.solo_presencial && b == FriendshipMeetMode.solo_virtual) return false;
    return true;
  }

  bool _isGenderCompatible(List<GenderInterest> myInterests, String? candidateGenderStr) {
     if (myInterests.contains(GenderInterest.sin_preferencia) || myInterests.isEmpty) return true;
     if (candidateGenderStr == null) return false; // If gender unknown, and strict filter? Let's hide.

     final candidateGender = _normalizeGender(candidateGenderStr);
     
     // Check if ANY of my interests match the candidate's gender
     // Mapping:
     // Mujer -> mujeres
     // Hombre -> hombres
     // No Binario/Otro -> no_binario_otres
     
     if (candidateGender == 'mujer' && myInterests.contains(GenderInterest.mujeres)) return true;
     if (candidateGender == 'hombre' && myInterests.contains(GenderInterest.hombres)) return true;
     if ((candidateGender == 'nobinario' || candidateGender == 'otro') && myInterests.contains(GenderInterest.no_binario_otres)) return true;
     
     return false;
  }

  String _normalizeGender(String g) {
      final lower = g.toLowerCase().trim();
      if (lower.contains('mujer') || lower.contains('femenino')) return 'mujer';
      if (lower.contains('hombre') || lower.contains('masculino')) return 'hombre';
      if (lower.contains('binario')) return 'nobinario';
      return 'otro';
  }

  double _calculateDistance(Map<String, dynamic> locA, Map<String, dynamic> locB) {
      try {
        final lat1 = (locA['lat'] as num).toDouble();
        final lon1 = (locA['lng'] as num).toDouble();
        final lat2 = (locB['lat'] as num).toDouble();
        final lon2 = (locB['lng'] as num).toDouble();
        
        const r = 6371; // Earth radius in km
        const p = 0.017453292519943295; // Pi/180
        
        final a = 0.5 - cos((lat2 - lat1) * p)/2 + 
                  cos(lat1 * p) * cos(lat2 * p) * 
                  (1 - cos((lon2 - lon1) * p))/2;
        
        return 12742 * asin(sqrt(a)); 
      } catch (e) {
          return 0;
      }
  }
}
