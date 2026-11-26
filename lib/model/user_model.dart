class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String description;
  final int? avatarColorValue;
  final bool subscribeNewsletter;
  final bool isOnboardingCompleted;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.description = '',
    this.avatarColorValue,
    this.subscribeNewsletter = true,
    this.isOnboardingCompleted = false,
    required this.createdAt,
  });

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? description,
    int? avatarColorValue,
    bool? subscribeNewsletter,
    bool? isOnboardingCompleted,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      description: description ?? this.description,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      subscribeNewsletter: subscribeNewsletter ?? this.subscribeNewsletter,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl ?? '',
      'description': description,
      'avatarColorValue': avatarColorValue,
      'subscribeNewsletter': subscribeNewsletter,
      'isOnboardingCompleted': isOnboardingCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      description: map['description'] ?? '',
      avatarColorValue: map['avatarColorValue'] is int
          ? map['avatarColorValue']
          : int.tryParse(map['avatarColorValue']?.toString() ?? ''),
      subscribeNewsletter: map['subscribeNewsletter'] ?? true,
      isOnboardingCompleted: map['isOnboardingCompleted'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}