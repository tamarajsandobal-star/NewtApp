import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_social/features/user/domain/models/app_user.dart';
import 'package:neuro_social/features/user/domain/models/user_photo.dart';
import 'package:neuro_social/features/user/domain/models/user_dealbreakers.dart';
import 'package:neuro_social/features/user/domain/models/user_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  test('AppUser serialization with new fields', () {
    final now = DateTime.now();
    final photo = UserPhoto(url: 'http://foo.com', isPrimary: true, uploadedAt: now);
    final dealbreakers = UserDealbreakers(
        datingSoft: ['Smoker'],
        datingHard: ['Substancias'],
        friendshipSoft: [],
        friendshipHard: ['Racism']
    );

    final user = AppUser(
        uid: 'user1',
        createdAt: now,
        updatedAt: now,
        photos: [photo],
        profileDescription: "I am complex",
        identityTags: ['Introvert', 'Night Owl'],
        deepInterests: ['Astronomy', 'Psychology'],
        questionnaire: {'q1': 5, 'q2': 1},
        dealbreakers: dealbreakers,
    );

    final map = user.toMap();
    
    expect(map['photos'], isNotEmpty);
    expect(map['photos'][0]['url'], 'http://foo.com');
    expect(map['dealbreakers']['datingHard'], contains('Substancias'));
    expect(map['profileDescription'], 'I am complex');

    final reconstructed = AppUser.fromMap(map, 'user1');
    expect(reconstructed.photos.length, 1);
    expect(reconstructed.dealbreakers.friendshipHard, contains('Racism'));
    expect(reconstructed.questionnaire['q1'], 5);
  });
}
