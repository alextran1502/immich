import 'dart:convert';

class LoginParamsResponse {
  final bool localAuth;
  final bool oauth2;
  final String issuer;
  final String clientId;

  LoginParamsResponse({
    required this.localAuth,
    required this.oauth2,
    required this.issuer,
    required this.clientId,
  });

  LoginParamsResponse copyWith({
    bool? localAuth,
    bool? oauth2,
    String? issuer,
    String? clientId,
  }) {
    return LoginParamsResponse(
      localAuth: localAuth ?? this.localAuth,
      oauth2: oauth2 ?? this.oauth2,
      issuer: issuer ?? this.issuer,
      clientId: clientId ?? this.clientId,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'localAuth': localAuth});
    result.addAll({'oauth2': oauth2});
    result.addAll({'issuer': issuer});
    result.addAll({'clientId': clientId});

    return result;
  }

  factory LoginParamsResponse.fromMap(Map<String, dynamic> map) {

    if (map['oauth2'] == true) {
      if (map['issuer'] == null) throw Exception("No issuer found in response");
      if (map['clientId'] == null) throw Exception("No client id found in response");
    }

    return LoginParamsResponse(
      localAuth: map['localAuth'] ?? false,
      oauth2: map['oauth2'] ?? false,
      issuer: map['issuer'] ?? '',
      clientId: map['clientId'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LoginParamsResponse.fromJson(String source) => LoginParamsResponse.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LoginParamsResponse(localAuth: $localAuth, oauth2: $oauth2, issuer: $issuer, clientId: $clientId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoginParamsResponse &&
        other.localAuth == localAuth &&
        other.oauth2 == oauth2 &&
        other.issuer == issuer &&
        other.clientId == clientId;
  }

  @override
  int get hashCode {
    return localAuth.hashCode ^
           oauth2.hashCode ^
           issuer.hashCode ^
           clientId.hashCode;
  }
}