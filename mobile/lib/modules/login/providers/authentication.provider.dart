import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:immich_mobile/modules/login/models/authentication_state.model.dart';
import 'package:immich_mobile/modules/login/models/hive_saved_login_info.model.dart';
import 'package:immich_mobile/modules/login/models/login_params_response.model.dart';
import 'package:immich_mobile/modules/login/models/login_response.model.dart';
import 'package:immich_mobile/modules/backup/services/backup.service.dart';
import 'package:immich_mobile/modules/login/models/validate_token_response.model.dart';
import 'package:immich_mobile/modules/login/services/local_auth.service.dart';
import 'package:immich_mobile/modules/login/services/oauth2.service.dart';
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
      bool isSavedLoginInfo, bool oauth2Login) async {
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

    LoginParamsResponse loginParams;

    try {
      Response res = await _networkService.getRequest(url: 'auth/loginParams');
      loginParams = LoginParamsResponse.fromJson(res.toString());
    } catch (e) {
      return false;
    }

    // Make sign-in request
    try {
      bool loggedIn = false;

      if (loginParams.oauth2 == true && oauth2Login) {
        loggedIn |=
        await OAuth2Service.tryLogin(loginParams.issuer, loginParams.clientId);
      }

      if (loginParams.localAuth == true && !oauth2Login) {
        loggedIn |=
        await LocalAuthService.tryLogin(email, password, _networkService);
      }

      if (!loggedIn) return false;
    } catch(e) {
      return false;
    }

    try {
      var s = await finalizeLogin();
      if (!s) return false;
    } catch (e) {
      return false;
    }

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

    return true;
  }

  Future<bool> finalizeLogin() async {
    try {
      debugPrint("Retrieving user details");

      Response res = await _networkService.getRequest(url: 'user/me');
      var payload = ValidateTokenReponse.fromJson(res.toString());

      state = state.copyWith(
        isAuthenticated: true,
        userId: payload.id,
        userEmail: payload.email,
        firstName: payload.firstName,
        lastName: payload.lastName,
        profileImagePath: payload.profileImagePath,
        isAdmin: payload.isAdmin,
        shouldChangePassword: payload.shouldChangePassword,
      );
    } catch(e) {
      return false;
    }

    // Register device info
    try {

      // Store device id to local storage
      var deviceInfo = await _deviceInfoService.getDeviceInfo();
      Hive.box(userInfoBox).put(deviceIdKey, deviceInfo["deviceId"]);

      state = state.copyWith(
        deviceId: deviceInfo["deviceId"],
        deviceType: deviceInfo["deviceType"],
      );
      
      Response res = await _networkService.postRequest(
        url: 'device-info',
        data: {
          'deviceId': state.deviceId,
          'deviceType': state.deviceType,
        },
      );

      DeviceInfoRemote deviceInfoRemote = DeviceInfoRemote.fromJson(res.toString());
      state = state.copyWith(deviceInfo: deviceInfoRemote);
    } catch (e) {
      debugPrint("ERROR Register Device Info: $e");
    }

    return true;
  }

  Future<bool> logout() async {
    Hive.box(userInfoBox).delete(accessTokenKey);
    Hive.box(userInfoBox).delete(refreshTokenKey);
    Hive.box(userInfoBox).delete(oauth2ClientIdKey);
    Hive.box(userInfoBox).delete(oAuth2RedirectUri);
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

  Future<bool> refreshLogin() async {
    var refreshedOAuth2Token = await OAuth2Service.refreshToken();

    if (refreshedOAuth2Token) {
      state = state.copyWith(
          isAuthenticated: true,
      );
      return true;
    }

    HiveSavedLoginInfo? loginInfo = Hive.box<HiveSavedLoginInfo>(hiveLoginInfoBox).get(savedLoginInfoKey);

    var isAuthenticated = await LocalAuthService.tryLogin(loginInfo!.email, loginInfo.password, _networkService);

    if (isAuthenticated) {
      return true;
    }

    return false;
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
