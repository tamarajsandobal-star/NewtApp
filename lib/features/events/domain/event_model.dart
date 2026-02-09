import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String city;
  final List<String> tags;
  final DateTime startAt;
  final String organizerId;
  final Map<String, dynamic> safetyFlags; // { 'quietArea': true, 'maxCapacity': 20 }
  final int trendingScore;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.city,
    required this.tags,
    required this.startAt,
    required this.organizerId,
    required this.safetyFlags,
    this.trendingScore = 0,
  });

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      city: map['city'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      startAt: (map['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      organizerId: map['organizerId'] ?? '',
      safetyFlags: Map<String, dynamic>.from(map['safetyFlags'] ?? {}),
      trendingScore: map['trendingScore'] ?? 0,
    );
  }
}
