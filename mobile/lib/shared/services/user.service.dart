import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:immich_mobile/shared/models/upload_profile_image_repsonse.model.dart';
import 'package:immich_mobile/shared/models/user.model.dart';
import 'package:immich_mobile/shared/services/network.service.dart';
import 'package:immich_mobile/utils/files_helper.dart';

final userServiceProvider =
    Provider((ref) => UserService(ref.watch(networkServiceProvider)));

class UserService {
  final NetworkService _networkService;
  UserService(this._networkService);

  Future<List<User>> getAllUsersInfo() async {
    try {
      var res = await _networkService.getRequest(url: 'user');
      List<dynamic> decodedData = jsonDecode(res.toString());
      List<User> result = List.from(decodedData.map((e) => User.fromMap(e)));

      return result;
    } catch (e) {
      debugPrint("Error getAllUsersInfo  ${e.toString()}");
    }

    return [];
  }

  Future<UploadProfileImageResponse?> uploadProfileImage(XFile image) async {
    String savedEndpoint = Hive.box(userInfoBox).get(serverEndpointKey);
    var mimeType = FileHelper.getMimeType(image.path);

    final imageData = MultipartFile.fromBytes(
      await image.readAsBytes(),
      filename: image.name,
      contentType: MediaType(
        mimeType["type"],
        mimeType["subType"],
      ),
    );

    final formData = FormData.fromMap({'file': imageData});

    try {
      Response res = await _networkService.dio.post(
        '$savedEndpoint/user/profile-image',
        data: formData,
      );

      var payload = UploadProfileImageResponse.fromJson(res.toString());

      return payload;
    } on DioError catch (e) {
      debugPrint("Error uploading file: ${e.response}");
      return null;
    } catch (e) {
      debugPrint("Error uploading file: $e");
      return null;
    }
  }
}
