class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool marketingOptIn;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.marketingOptIn = false,
    required this.createdAt,
  });

  UserProfile copyWith({bool? marketingOptIn}) => UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        marketingOptIn: marketingOptIn ?? this.marketingOptIn,
        createdAt: createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'marketingOptIn': marketingOptIn,
        'createdAt': createdAt.toIso8601String(),
        'lastSeenAt': DateTime.now().toIso8601String(),
        'platform': 'android',
      };
}
