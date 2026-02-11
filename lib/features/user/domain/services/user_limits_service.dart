import '../models/app_user.dart';
import '/core/enums/app_enums.dart';

class UserLimitsService {
  static const int _freeLikesDating = 15;
  static const int _freeLikesFriendship = 25;

  /// Checks if limits need to be reset based on lastResetAt.
  /// Returns a new UserLimits object if reset is needed, otherwise returns the original.
  UserLimits checkDailyReset(UserLimits limits) {
    final now = DateTime.now();
    final lastReset = limits.lastResetAt;

    if (lastReset == null ||
        lastReset.year != now.year ||
        lastReset.month != now.month ||
        lastReset.day != now.day) {
      return UserLimits(
        dailyLikesDatingMax: limits.dailyLikesDatingMax, // Preserve max settings
        dailyLikesFriendshipMax: limits.dailyLikesFriendshipMax,
        dailyLikesDatingUsed: 0,
        dailyLikesFriendshipUsed: 0,
        lastResetAt: now,
      );
    }
    return limits;
  }

  /// Checks if the user can perform a like action in the given mode.
  bool canLike(AppUser user, AppMode mode) {
    // If premium, always true (assuming premium has high/unlimited limits logic handled elsewhere or max is set very high)
    if (user.subscriptionTier == SubscriptionTier.premium) return true;

    final limits = user.limits; // Assumed to be up-to-date (checked for reset)
    
    switch (mode) {
      case AppMode.dating:
        return limits.dailyLikesDatingUsed < (user.subscriptionTier == SubscriptionTier.premium ? 9999 : _freeLikesDating);
      case AppMode.friendship:
        return limits.dailyLikesFriendshipUsed < (user.subscriptionTier == SubscriptionTier.premium ? 9999 : _freeLikesFriendship);
    }
  }

  /// Returns a new UserLimits object with the counter incremented.
  UserLimits incrementLike(UserLimits limits, AppMode mode) {
    switch (mode) {
      case AppMode.dating:
        return UserLimits(
          dailyLikesDatingMax: limits.dailyLikesDatingMax,
          dailyLikesFriendshipMax: limits.dailyLikesFriendshipMax,
          dailyLikesDatingUsed: limits.dailyLikesDatingUsed + 1,
          dailyLikesFriendshipUsed: limits.dailyLikesFriendshipUsed,
          lastResetAt: limits.lastResetAt,
        );
      case AppMode.friendship:
        return UserLimits(
          dailyLikesDatingMax: limits.dailyLikesDatingMax,
          dailyLikesFriendshipMax: limits.dailyLikesFriendshipMax,
          dailyLikesDatingUsed: limits.dailyLikesDatingUsed,
          dailyLikesFriendshipUsed: limits.dailyLikesFriendshipUsed + 1,
          lastResetAt: limits.lastResetAt,
        );
    }
  }
}
