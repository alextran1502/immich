import 'dart:convert';

class ValidateTokenReponse {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String profileImagePath;
  final bool isAdmin;
  final bool shouldChangePassword;

  ValidateTokenReponse({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.profileImagePath,
    required this.isAdmin,
    required this.shouldChangePassword,
  });

  ValidateTokenReponse copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImagePath,
    bool? isAdmin,
    bool? shouldChangePassword,
  }) {
    return ValidateTokenReponse(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isAdmin: isAdmin ?? this.isAdmin,
      shouldChangePassword: shouldChangePassword ?? this.shouldChangePassword,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'email': email});
    result.addAll({'firstName': firstName});
    result.addAll({'lastName': lastName});
    result.addAll({'profileImagePath': profileImagePath});
    result.addAll({'isAdmin': isAdmin});
    result.addAll({'shouldChangePassword': shouldChangePassword});

    return result;
  }

  factory ValidateTokenReponse.fromMap(Map<String, dynamic> map) {
    return ValidateTokenReponse(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      profileImagePath: map['profileImagePath'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      shouldChangePassword: map['shouldChangePassword'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ValidateTokenReponse.fromJson(String source) => ValidateTokenReponse.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LogInReponse(id: $id, email: $email, firstName: $firstName, lastName: $lastName, profileImagePath: $profileImagePath, isAdmin: $isAdmin, shouldChangePassword: $shouldChangePassword)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ValidateTokenReponse &&
        other.id == id &&
        other.email == email &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.profileImagePath == profileImagePath &&
        other.isAdmin == isAdmin &&
        other.shouldChangePassword == shouldChangePassword;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        profileImagePath.hashCode ^
        isAdmin.hashCode ^
        shouldChangePassword.hashCode;
  }
}