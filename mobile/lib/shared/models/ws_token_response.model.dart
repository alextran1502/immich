import 'dart:convert';

class WsTokenResponse {
  final String wsToken;

  WsTokenResponse({
    required this.wsToken,
  });

  WsTokenResponse copyWith({
    String? wsToken,
  }) {
    return WsTokenResponse(
      wsToken: wsToken ?? this.wsToken,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'wsToken': wsToken});

    return result;
  }

  factory WsTokenResponse.fromMap(Map<String, dynamic> map) {
    return WsTokenResponse(
      wsToken: map['wsToken'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory WsTokenResponse.fromJson(String source) => WsTokenResponse.fromMap(json.decode(source));

  @override
  String toString() => 'WsTokenResponse(wsToken: $wsToken)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WsTokenResponse && other.wsToken == wsToken;
  }

  @override
  int get hashCode => wsToken.hashCode;
}
