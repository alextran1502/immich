import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/home/models/delete_asset_response.model.dart';
import 'package:immich_mobile/modules/home/models/get_all_asset_response.model.dart';
import 'package:immich_mobile/shared/models/immich_asset.model.dart';
import 'package:immich_mobile/shared/models/immich_asset_with_exif.model.dart';
import 'package:immich_mobile/shared/services/network.service.dart';

final assetServiceProvider =
    Provider((ref) => AssetService(ref.watch(networkServiceProvider)));

class AssetService {
  final NetworkService _networkService;
  AssetService(this._networkService);

  Future<List<ImmichAsset>?> getAllAsset() async {
    var res = await _networkService.getRequest(url: "asset/");
    try {
      List<dynamic> decodedData = jsonDecode(res.toString());

      List<ImmichAsset> result =
          List.from(decodedData.map((a) => ImmichAsset.fromMap(a)));
      return result;
    } catch (e) {
      debugPrint("Error getAllAsset  ${e.toString()}");
    }
    return null;
  }

  Future<GetAllAssetResponse?> getAllAssetWithPagination() async {
    var res = await _networkService.getRequest(url: "asset/all");
    try {
      Map<String, dynamic> decodedData = jsonDecode(res.toString());

      GetAllAssetResponse result = GetAllAssetResponse.fromMap(decodedData);
      return result;
    } catch (e) {
      debugPrint("Error getAllAsset  ${e.toString()}");
    }
    return null;
  }

  Future<GetAllAssetResponse?> getOlderAsset(String? nextPageKey) async {
    try {
      var res = await _networkService.getRequest(
        url: "asset/all?nextPageKey=$nextPageKey",
      );

      Map<String, dynamic> decodedData = jsonDecode(res.toString());

      GetAllAssetResponse result = GetAllAssetResponse.fromMap(decodedData);
      if (result.count != 0) {
        return result;
      }
    } catch (e) {
      debugPrint("Error getAllAsset  ${e.toString()}");
    }
    return null;
  }

  Future<List<ImmichAsset>> getNewAsset(String latestDate) async {
    try {
      var res = await _networkService.getRequest(
        url: "asset/new?latestDate=$latestDate",
      );

      List<dynamic> decodedData = jsonDecode(res.toString());

      List<ImmichAsset> result =
          List.from(decodedData.map((a) => ImmichAsset.fromMap(a)));
      if (result.isNotEmpty) {
        return result;
      }

      return [];
    } catch (e) {
      debugPrint("Error getAllAsset  ${e.toString()}");
      return [];
    }
  }

  Future<ImmichAssetWithExif?> getAssetById(String assetId) async {
    try {
      var res = await _networkService.getRequest(
        url: "asset/assetById/$assetId",
      );

      Map<String, dynamic> decodedData = jsonDecode(res.toString());

      ImmichAssetWithExif result = ImmichAssetWithExif.fromMap(decodedData);
      return result;
    } catch (e) {
      debugPrint("Error getAllAsset  ${e.toString()}");
      return null;
    }
  }

  Future<List<DeleteAssetResponse>?> deleteAssets(
      Set<ImmichAsset> deleteAssets) async {
    try {
      var payload = [];

      for (var asset in deleteAssets) {
        payload.add(asset.id);
      }

      var res = await _networkService
          .deleteRequest(url: "asset/", data: {"ids": payload});

      List<dynamic> decodedData = jsonDecode(res.toString());

      List<DeleteAssetResponse> result =
          List.from(decodedData.map((a) => DeleteAssetResponse.fromMap(a)));

      return result;
    } catch (e) {
      debugPrint("Error getAllAsset  ${e.toString()}");
      return null;
    }
  }
}
