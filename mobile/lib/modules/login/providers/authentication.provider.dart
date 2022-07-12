import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:immich_mobile/modules/login/models/authentication_state.model.dart';
import 'package:immich_mobile/modules/login/models/hive_saved_login_info.model.dart';
import 'package:immich_mobile/modules/login/models/login_response.model.dart';
import 'package:immich_mobile/modules/backup/services/backup.service.dart';
import 'package:immich_mobile/shared/services/device_info.service.dart';
import 'package:immich_mobile/shared/services/network.service.dart';
import 'package:immich_mobile/shared/models/device_info.model.dart';

class AuthenticationNotifier extends StateNotifier<AuthenticationState> {
  AuthenticationNotifier(
      this._deviceInfoService, this._backupService, this._networkService)
      : super(
          AuthenticationState(
            deviceId: "",
            deviceType: "",
            userId: "",
            userEmail: "",
            firstName: '',
            lastName: '',
            profileImagePath: '',
            isAdmin: false,
            shouldChangePassword: false,
            isAuthenticated: false,
            deviceInfo: DeviceInfoRemote(
              id: 0,
              userId: "",
              deviceId: "",
              deviceType: "",
              notificationToken: "",
              createdAt: "",
              isAutoBackup: false,
            ),
          ),
        );

  final DeviceInfoService _deviceInfoService;
  final BackupService _backupService;
  final NetworkService _networkService;

  Future<bool> login(String email, String password, String serverEndpoint,
      bool isSavedLoginInfo) async {
    // Store server endpoint to Hive and test endpoint
    if (serverEndpoint[serverEndpoint.length - 1] == "/") {
      var validUrl = serverEndpoint.substring(0, serverEndpoint.length - 1);
      Hive.box(userInfoBox).put(serverEndpointKey, validUrl);
    } else {
      Hive.box(userInfoBox).put(serverEndpointKey, serverEndpoint);
    }

    try {
      bool isServerEndpointVerified = await _networkService.pingServer();
      if (!isServerEndpointVerified) {
        return false;
      }
    } catch (e) {
      return false;
    }

    // Store device id to local storage
    var deviceInfo = await _deviceInfoService.getDeviceInfo();
    Hive.box(userInfoBox).put(deviceIdKey, deviceInfo["deviceId"]);

    var localState = state.copyWith(
      deviceId: deviceInfo["deviceId"],
      deviceType: deviceInfo["deviceType"],
    );

    // Make sign-in request
    try {
      Response res = await _networkService.postRequest(
          url: 'auth/login', data: {'email': email, 'password': password});

      var payload = LogInReponse.fromJson(res.toString());

      Hive.box(userInfoBox).put(accessTokenKey, payload.accessToken);

      localState = localState.copyWith(
        isAuthenticated: true,
        userId: payload.userId,
        userEmail: payload.userEmail,
        firstName: payload.firstName,
        lastName: payload.lastName,
        profileImagePath: payload.profileImagePath,
        isAdmin: payload.isAdmin,
        shouldChangePassword: payload.shouldChangePassword,
      );

      if (isSavedLoginInfo) {
        // Save login info to local storage
        Hive.box<HiveSavedLoginInfo>(hiveLoginInfoBox).put(
          savedLoginInfoKey,
          HiveSavedLoginInfo(
              email: email,
              password: password,
              isSaveLogin: true,
              serverUrl: Hive.box(userInfoBox).get(serverEndpointKey)),
        );
      } else {
        Hive.box<HiveSavedLoginInfo>(hiveLoginInfoBox)
            .delete(savedLoginInfoKey);
      }
    } catch (e) {
      return false;
    }

    // Register device info
    try {
      Response res = await _networkService.postRequest(
        url: 'device-info',
        data: {
          'deviceId': localState.deviceId,
          'deviceType': localState.deviceType,
        },
      );

      DeviceInfoRemote deviceInfo = DeviceInfoRemote.fromJson(res.toString());
      state = localState.copyWith(deviceInfo: deviceInfo);
    } catch (e) {
      debugPrint("ERROR Register Device Info: $e");
    }

    return true;
  }

  Future<bool> logout() async {
    Hive.box(userInfoBox).delete(accessTokenKey);
    state = AuthenticationState(
      deviceId: "",
      deviceType: "",
      userId: "",
      userEmail: "",
      firstName: '',
      lastName: '',
      profileImagePath: '',
      shouldChangePassword: false,
      isAuthenticated: false,
      isAdmin: false,
      deviceInfo: DeviceInfoRemote(
        id: 0,
        userId: "",
        deviceId: "",
        deviceType: "",
        notificationToken: "",
        createdAt: "",
        isAutoBackup: false,
      ),
    );

    return true;
  }

  setAutoBackup(bool backupState) async {
    var deviceInfo = await _deviceInfoService.getDeviceInfo();
    var deviceId = deviceInfo["deviceId"];
    var deviceType = deviceInfo["deviceType"];

    DeviceInfoRemote deviceInfoRemote =
        await _backupService.setAutoBackup(backupState, deviceId, deviceType);
    state = state.copyWith(deviceInfo: deviceInfoRemote);
  }

  updateUserProfileImagePath(String path) {
    state = state.copyWith(profileImagePath: path);
  }

  Future<bool> changePassword(String newPassword) async {
    Response res = await _networkService.putRequest(
      url: 'user',
      data: {
        'id': state.userId,
        'password': newPassword,
        'shouldChangePassword': false,
      },
    );

    if (res.statusCode == 200) {
      state = state.copyWith(shouldChangePassword: false);
      return true;
    } else {
      return false;
    }
  }
}

final authenticationProvider =
    StateNotifierProvider<AuthenticationNotifier, AuthenticationState>((ref) {
  return AuthenticationNotifier(
    ref.watch(deviceInfoServiceProvider),
    ref.watch(backupServiceProvider),
    ref.watch(networkServiceProvider),
  );
});
