import '/core/enums/app_enums.dart';

class LikeModel {
  final String uid; // The user who *received* the like (if this is incoming) or *was liked* (if outgoing) - actually context dependent.
  // Prompt: likesDating/{uid}/outgoing/{otherUid}
  // If I fetch my outgoing likes, the doc ID is otherUid.
  // If I fetch my incoming likes, the doc ID is otherUid (the liker).
  // Let's store targetUserId and currentUserId explicitly if needed, or just `userId`.
  
  final DateTime createdAt;
  final AppMode mode;
  final String? highlightComment; // Only for friendship

  LikeModel({
    required this.uid, 
    required this.createdAt,
    required this.mode,
    this.highlightComment,
  });
}
