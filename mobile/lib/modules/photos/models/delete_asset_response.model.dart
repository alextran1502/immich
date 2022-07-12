import 'dart:convert';

class DeleteAssetResponse {
  final String id;
  final String status;

  DeleteAssetResponse({
    required this.id,
    required this.status,
  });

  DeleteAssetResponse copyWith({
    String? id,
    String? status,
  }) {
    return DeleteAssetResponse(
      id: id ?? this.id,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
    };
  }

  factory DeleteAssetResponse.fromMap(Map<String, dynamic> map) {
    return DeleteAssetResponse(
      id: map['id'] ?? '',
      status: map['status'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DeleteAssetResponse.fromJson(String source) =>
      DeleteAssetResponse.fromMap(json.decode(source));

  @override
  String toString() => 'DeleteAssetResponse(id: $id, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeleteAssetResponse &&
        other.id == id &&
        other.status == status;
  }

  @override
  int get hashCode => id.hashCode ^ status.hashCode;
}
