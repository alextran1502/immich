import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:immich_mobile/shared/models/immich_asset.model.dart';

class ImmichAssetGroupByDate {
  final String date;
  List<ImmichAsset> assets;
  ImmichAssetGroupByDate({
    required this.date,
    required this.assets,
  });

  ImmichAssetGroupByDate copyWith({
    String? date,
    List<ImmichAsset>? assets,
  }) {
    return ImmichAssetGroupByDate(
      date: date ?? this.date,
      assets: assets ?? this.assets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'assets': assets.map((x) => x.toMap()).toList(),
    };
  }

  factory ImmichAssetGroupByDate.fromMap(Map<String, dynamic> map) {
    return ImmichAssetGroupByDate(
      date: map['date'] ?? '',
      assets: List<ImmichAsset>.from(
          map['assets']?.map((x) => ImmichAsset.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory ImmichAssetGroupByDate.fromJson(String source) =>
      ImmichAssetGroupByDate.fromMap(json.decode(source));

  @override
  String toString() => 'ImmichAssetGroupByDate(date: $date, assets: $assets)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ImmichAssetGroupByDate &&
        other.date == date &&
        listEquals(other.assets, assets);
  }

  @override
  int get hashCode => date.hashCode ^ assets.hashCode;
}

class GetAllAssetResponse {
  final int count;
  final List<ImmichAssetGroupByDate> data;
  final String nextPageKey;
  GetAllAssetResponse({
    required this.count,
    required this.data,
    required this.nextPageKey,
  });

  GetAllAssetResponse copyWith({
    int? count,
    List<ImmichAssetGroupByDate>? data,
    String? nextPageKey,
  }) {
    return GetAllAssetResponse(
      count: count ?? this.count,
      data: data ?? this.data,
      nextPageKey: nextPageKey ?? this.nextPageKey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'data': data.map((x) => x.toMap()).toList(),
      'nextPageKey': nextPageKey,
    };
  }

  factory GetAllAssetResponse.fromMap(Map<String, dynamic> map) {
    return GetAllAssetResponse(
      count: map['count']?.toInt() ?? 0,
      data: List<ImmichAssetGroupByDate>.from(
          map['data']?.map((x) => ImmichAssetGroupByDate.fromMap(x))),
      nextPageKey: map['nextPageKey'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory GetAllAssetResponse.fromJson(String source) =>
      GetAllAssetResponse.fromMap(json.decode(source));

  @override
  String toString() =>
      'GetAllAssetResponse(count: $count, data: $data, nextPageKey: $nextPageKey)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GetAllAssetResponse &&
        other.count == count &&
        listEquals(other.data, data) &&
        other.nextPageKey == nextPageKey;
  }

  @override
  int get hashCode => count.hashCode ^ data.hashCode ^ nextPageKey.hashCode;
}
