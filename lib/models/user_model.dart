class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final int age;
  final double weightKg;
  final String? profilePictureUrl;
  final bool biometricEnabled;
  final String? webCredentialId;
  final String? gender;
  final String? fitnessGoal;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.age,
    required this.weightKg,
    this.profilePictureUrl,
    this.biometricEnabled = false,
    this.webCredentialId,
    this.gender,
    this.fitnessGoal,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        email: map['email'] ?? '',
        fullName: map['fullName'] ?? '',
        age: map['age'] ?? 0,
        weightKg: (map['weightKg'] ?? 0).toDouble(),
        profilePictureUrl: map['profilePictureUrl'],
        biometricEnabled: map['biometricEnabled'] ?? false,
        webCredentialId: map['webCredentialId'],
        gender: map['gender'],
        fitnessGoal: map['fitnessGoal'],
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'age': age,
        'weightKg': weightKg,
        'profilePictureUrl': profilePictureUrl,
        'biometricEnabled': biometricEnabled,
        'webCredentialId': webCredentialId,
        'gender': gender,
        'fitnessGoal': fitnessGoal,
      };

  UserModel copyWith({
    String? fullName,
    int? age,
    double? weightKg,
    String? profilePictureUrl,
    bool? biometricEnabled,
    String? webCredentialId,
    String? gender,
    String? fitnessGoal,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        fullName: fullName ?? this.fullName,
        age: age ?? this.age,
        weightKg: weightKg ?? this.weightKg,
        profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        webCredentialId: webCredentialId ?? this.webCredentialId,
        gender: gender ?? this.gender,
        fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      );

  String get weightCategory {
    // FIX: Use a reasonable BMI approximation with average height (1.65m).
    // Previous logic used weight alone which is inaccurate —
    // e.g. a 90kg person who is 1.9m tall is not overweight.
    const double avgHeight = 1.65;
    final bmi = weightKg / (avgHeight * avgHeight);
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  // Helper for base64 images
  bool get isBase64Image =>
      profilePictureUrl?.startsWith('data:image/') ?? false;

  String get ageGroup => age < 50 ? 'Under50' : 'Over50';
}
