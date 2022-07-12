import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:immich_mobile/shared/models/immich_asset.model.dart';
import 'package:immich_mobile/shared/models/user.model.dart';

class SharedAlbum {
  final String id;
  final String ownerId;
  final String albumName;
  final String createdAt;
  final String? albumThumbnailAssetId;
  final List<User> sharedUsers;
  final List<ImmichAsset>? assets;

  SharedAlbum({
    required this.id,
    required this.ownerId,
    required this.albumName,
    required this.createdAt,
    required this.albumThumbnailAssetId,
    required this.sharedUsers,
    this.assets,
  });

  SharedAlbum copyWith({
    String? id,
    String? ownerId,
    String? albumName,
    String? createdAt,
    String? albumThumbnailAssetId,
    List<User>? sharedUsers,
    List<ImmichAsset>? assets,
  }) {
    return SharedAlbum(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      albumName: albumName ?? this.albumName,
      createdAt: createdAt ?? this.createdAt,
      albumThumbnailAssetId:
          albumThumbnailAssetId ?? this.albumThumbnailAssetId,
      sharedUsers: sharedUsers ?? this.sharedUsers,
      assets: assets ?? this.assets,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'ownerId': ownerId});
    result.addAll({'albumName': albumName});
    result.addAll({'createdAt': createdAt});
    if (albumThumbnailAssetId != null) {
      result.addAll({'albumThumbnailAssetId': albumThumbnailAssetId});
    }
    result.addAll({'sharedUsers': sharedUsers.map((x) => x.toMap()).toList()});
    if (assets != null) {
      result.addAll({'assets': assets!.map((x) => x.toMap()).toList()});
    }

    return result;
  }

  factory SharedAlbum.fromMap(Map<String, dynamic> map) {
    return SharedAlbum(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      albumName: map['albumName'] ?? '',
      createdAt: map['createdAt'] ?? '',
      albumThumbnailAssetId: map['albumThumbnailAssetId'],
      sharedUsers:
          List<User>.from(map['sharedUsers']?.map((x) => User.fromMap(x))),
      assets: map['assets']?.map((x) => ImmichAsset.fromMap(x)).toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SharedAlbum.fromJson(String source) =>
      SharedAlbum.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SharedAlbum(id: $id, ownerId: $ownerId, albumName: $albumName, createdAt: $createdAt, albumThumbnailAssetId: $albumThumbnailAssetId, sharedUsers: $sharedUsers, assets: $assets)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is SharedAlbum &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.albumName == albumName &&
        other.createdAt == createdAt &&
        other.albumThumbnailAssetId == albumThumbnailAssetId &&
        listEquals(other.sharedUsers, sharedUsers) &&
        listEquals(other.assets, assets);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ownerId.hashCode ^
        albumName.hashCode ^
        createdAt.hashCode ^
        albumThumbnailAssetId.hashCode ^
        sharedUsers.hashCode ^
        assets.hashCode;
  }
}
