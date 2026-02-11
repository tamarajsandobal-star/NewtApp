
import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_social/features/user/domain/models/app_user.dart';
import 'package:neuro_social/features/user/domain/models/user_preferences.dart';
import 'package:neuro_social/features/user/domain/models/neuro_profile.dart';
import 'package:neuro_social/features/user/domain/models/user_interests.dart';
import 'package:neuro_social/features/user/domain/models/user_full_profile.dart';
import 'package:neuro_social/core/enums/app_enums.dart';
import 'package:neuro_social/features/discovery/domain/services/scoring_service.dart';
import 'package:neuro_social/features/discovery/domain/services/discovery_service.dart';

void main() {
  late ScoringService scoringService;
  late DiscoveryService discoveryService;

  setUp(() {
    scoringService = ScoringService();
    discoveryService = DiscoveryService(scoringService);
  });

  // Helper to create a basic user
  UserFullProfile createProfile({
    required String uid,
    required bool datingActive,
    required bool friendsActive,
    DatingPreferences? datingPrefs,
    FriendshipPreferences? friendshipPrefs,
    NeuroProfile? neuro,
    UserInterests? interests,
  }) {
    final user = AppUser(
      uid: uid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      birthDate: DateTime(1995, 1, 1), // 30 years old roughly
      settings: UserSettings(datingActive: datingActive, friendsActive: friendsActive),
    );

    return UserFullProfile(
      user: user,
      datingPreferences: datingPrefs,
      friendshipPreferences: friendshipPrefs,
      neuroProfile: neuro ?? const NeuroProfile(),
      interests: interests ?? const UserInterests(),
    );
  }

  group('DiscoveryService Logic', () {
    test('Dating: Monogamy Hard Filter excludes incompatible users', () async {
      final currentUser = createProfile(
        uid: 'user1',
        datingActive: true,
        friendsActive: false,
        datingPrefs: DatingPreferences(
          genderInterest: [GenderInterest.mujeres],
          ageRange: const AgeRange(min: 18, max: 99),
          distanceMaxKm: 50,
          relationalStructure: RelationalStructure.monogamia,
          intention: DatingIntention.pareja_estable,
        ),
      );

      final candidatePoly = createProfile(
        uid: 'user2',
        datingActive: true,
        friendsActive: false,
        datingPrefs: DatingPreferences(
          genderInterest: [GenderInterest.hombres],
          ageRange: const AgeRange(min: 18, max: 99),
          distanceMaxKm: 50,
          relationalStructure: RelationalStructure.poliamor,
          intention: DatingIntention.pareja_estable,
        ),
      );

      final candidateMono = createProfile(
        uid: 'user3',
        datingActive: true,
        friendsActive: false,
        datingPrefs: DatingPreferences(
          genderInterest: [GenderInterest.hombres],
          ageRange: const AgeRange(min: 18, max: 99),
          distanceMaxKm: 50,
          relationalStructure: RelationalStructure.monogamia,
          intention: DatingIntention.pareja_estable,
        ),
      );

      final candidates = await discoveryService.getDatingCandidates(
        currentUser: currentUser,
        allCandidates: [candidatePoly, candidateMono],
        blockedUserIds: {},
        alreadyInteractedUserIds: {},
      );

      expect(candidates.length, 1);
      expect(candidates.first.user.uid, 'user3');
    });

    test('Friendship: MeetMode Hard Filter excludes strict mismatch', () async {
      final currentUser = createProfile(
        uid: 'friend1',
        datingActive: false,
        friendsActive: true,
        friendshipPrefs: FriendshipPreferences(
          genderInterest: [GenderInterest.sin_preferencia],
          ageRange: const AgeRange(min: 18, max: 99),
          distanceMaxKm: 50,
          friendshipStyle: [],
          meetMode: FriendshipMeetMode.solo_virtual,
          contactFrequency: ContactFrequency.media,
        ),
      );

      final candidateStrictPresencial = createProfile(
        uid: 'friend2',
        datingActive: false,
        friendsActive: true,
        friendshipPrefs: FriendshipPreferences(
          genderInterest: [GenderInterest.sin_preferencia],
          ageRange: const AgeRange(min: 18, max: 99),
          distanceMaxKm: 50,
          friendshipStyle: [],
          meetMode: FriendshipMeetMode.solo_presencial,
          contactFrequency: ContactFrequency.media,
        ),
      );

      final candidateFlexible = createProfile(
        uid: 'friend3',
        datingActive: false,
        friendsActive: true,
        friendshipPrefs: FriendshipPreferences(
          genderInterest: [GenderInterest.sin_preferencia],
          ageRange: const AgeRange(min: 18, max: 99),
          distanceMaxKm: 50,
          friendshipStyle: [],
          meetMode: FriendshipMeetMode.flexible,
          contactFrequency: ContactFrequency.media,
        ),
      );

      final candidates = await discoveryService.getFriendshipCandidates(
        currentUser: currentUser,
        allCandidates: [candidateStrictPresencial, candidateFlexible],
        blockedUserIds: {},
        alreadyInteractedUserIds: {},
      );

      expect(candidates.length, 1);
      expect(candidates.first.user.uid, 'friend3');
    });

    test('Scoring: Intention match gives higher score in Dating', () {
      final p1 = createProfile(
        uid: 'u1', datingActive: true, friendsActive: false,
        datingPrefs: DatingPreferences(
            genderInterest: [], ageRange: const AgeRange(min: 18, max:99), distanceMaxKm: 100,
            relationalStructure: RelationalStructure.monogamia,
            intention: DatingIntention.pareja_estable
        )
      );
      
      final p2 = createProfile(
        uid: 'u2', datingActive: true, friendsActive: false,
        datingPrefs: DatingPreferences(
            genderInterest: [], ageRange: const AgeRange(min: 18, max:99), distanceMaxKm: 100,
            relationalStructure: RelationalStructure.monogamia,
            intention: DatingIntention.pareja_estable
        )
      );

       final p3 = createProfile(
        uid: 'u3', datingActive: true, friendsActive: false,
        datingPrefs: DatingPreferences(
            genderInterest: [], ageRange: const AgeRange(min: 18, max:99), distanceMaxKm: 100,
            relationalStructure: RelationalStructure.monogamia,
            intention: DatingIntention.solo_una_noche
        )
      );

      double scoreMatch = scoringService.calculateDatingScore(p1, p2);
      double scoreMismatch = scoringService.calculateDatingScore(p1, p3);

      // Intention weight is 20%. Difference between stable(5) and one-night(0) is 5 steps -> 0 pts.
      // Match gives 20 pts.
      // So scoreMatch should be roughly 20 points higher assuming everything else is equal (neuro, rhythm, interests which are defaults).
      
      expect(scoreMatch > scoreMismatch, isTrue);
    });
  });
}
