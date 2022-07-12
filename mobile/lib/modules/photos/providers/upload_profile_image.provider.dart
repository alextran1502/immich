import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:immich_mobile/shared/services/user.service.dart';

enum UploadProfileStatus {
  idle,
  loading,
  success,
  failure,
}

class UploadProfileImageState {
  // enum
  final UploadProfileStatus status;
  final String profileImagePath;
  UploadProfileImageState({
    required this.status,
    required this.profileImagePath,
  });

  UploadProfileImageState copyWith({
    UploadProfileStatus? status,
    String? profileImagePath,
  }) {
    return UploadProfileImageState(
      status: status ?? this.status,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'status': status.index});
    result.addAll({'profileImagePath': profileImagePath});

    return result;
  }

  factory UploadProfileImageState.fromMap(Map<String, dynamic> map) {
    return UploadProfileImageState(
      status: UploadProfileStatus.values[map['status'] ?? 0],
      profileImagePath: map['profileImagePath'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UploadProfileImageState.fromJson(String source) =>
      UploadProfileImageState.fromMap(json.decode(source));

  @override
  String toString() =>
      'UploadProfileImageState(status: $status, profileImagePath: $profileImagePath)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UploadProfileImageState &&
        other.status == status &&
        other.profileImagePath == profileImagePath;
  }

  @override
  int get hashCode => status.hashCode ^ profileImagePath.hashCode;
}

class UploadProfileImageNotifier
    extends StateNotifier<UploadProfileImageState> {
  UploadProfileImageNotifier(this._userSErvice)
      : super(UploadProfileImageState(
          profileImagePath: '',
          status: UploadProfileStatus.idle,
        ));

  final UserService _userSErvice;

  Future<bool> upload(XFile file) async {
    state = state.copyWith(status: UploadProfileStatus.loading);

    var res = await _userSErvice.uploadProfileImage(file);

    if (res != null) {
      debugPrint("Succesfully upload profile image");
      state = state.copyWith(
          status: UploadProfileStatus.success,
          profileImagePath: res.profileImagePath);
      return true;
    }

    state = state.copyWith(status: UploadProfileStatus.failure);
    return false;
  }
}

final uploadProfileImageProvider =
    StateNotifierProvider<UploadProfileImageNotifier, UploadProfileImageState>(
        ((ref) => UploadProfileImageNotifier(ref.watch(userServiceProvider))));
