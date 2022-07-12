import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:immich_mobile/modules/home/providers/upload_profile_image.provider.dart';

import 'package:immich_mobile/shared/providers/asset.provider.dart';
import 'package:immich_mobile/modules/login/models/authentication_state.model.dart';
import 'package:immich_mobile/modules/login/providers/authentication.provider.dart';
import 'package:immich_mobile/shared/models/server_info_state.model.dart';
import 'package:immich_mobile/modules/backup/providers/backup.provider.dart';
import 'package:immich_mobile/shared/providers/server_info.provider.dart';
import 'package:immich_mobile/shared/providers/websocket.provider.dart';
import 'package:immich_mobile/shared/ui/immich_loading_indicator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:math';

class ProfileDrawer extends HookConsumerWidget {
  const ProfileDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String endpoint = Hive.box(userInfoBox).get(serverEndpointKey);
    AuthenticationState authState = ref.watch(authenticationProvider);
    ServerInfoState serverInfoState = ref.watch(serverInfoProvider);
    final uploadProfileImageStatus =
        ref.watch(uploadProfileImageProvider).status;
    final appInfo = useState({});
    var dummmy = Random().nextInt(1024);

    _getPackageInfo() async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      appInfo.value = {
        "version": packageInfo.version,
        "buildNumber": packageInfo.buildNumber,
      };
    }

    _buildUserProfileImage() {
      if (authState.profileImagePath.isEmpty) {
        return const CircleAvatar(
          radius: 35,
          backgroundImage: AssetImage('assets/immich-logo-no-outline.png'),
          backgroundColor: Colors.transparent,
        );
      }

      if (uploadProfileImageStatus == UploadProfileStatus.idle) {
        if (authState.profileImagePath.isNotEmpty) {
          return CircleAvatar(
            radius: 35,
            backgroundImage: NetworkImage(
                '$endpoint/user/profile-image/${authState.userId}?d=${dummmy++}'),
            backgroundColor: Colors.transparent,
          );
        } else {
          return const CircleAvatar(
            radius: 35,
            backgroundImage: AssetImage('assets/immich-logo-no-outline.png'),
            backgroundColor: Colors.transparent,
          );
        }
      }

      if (uploadProfileImageStatus == UploadProfileStatus.success) {
        return CircleAvatar(
          radius: 35,
          backgroundImage: NetworkImage(
              '$endpoint/user/profile-image/${authState.userId}?d=${dummmy++}'),
          backgroundColor: Colors.transparent,
        );
      }

      if (uploadProfileImageStatus == UploadProfileStatus.failure) {
        return const CircleAvatar(
          radius: 35,
          backgroundImage: AssetImage('assets/immich-logo-no-outline.png'),
          backgroundColor: Colors.transparent,
        );
      }

      if (uploadProfileImageStatus == UploadProfileStatus.loading) {
        return const ImmichLoadingIndicator();
      }

      return const SizedBox();
    }

    _pickUserProfileImage() async {
      final XFile? image = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxHeight: 1024, maxWidth: 1024);

      if (image != null) {
        var success =
            await ref.watch(uploadProfileImageProvider.notifier).upload(image);

        if (success) {
          ref.watch(authenticationProvider.notifier).updateUserProfileImagePath(
              ref.read(uploadProfileImageProvider).profileImagePath);
        }
      }
    }

    useEffect(() {
      _getPackageInfo();
      _buildUserProfileImage();
      return null;
    }, []);
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 216, 219, 238),
                      Color.fromARGB(255, 226, 230, 231)
                    ],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildUserProfileImage(),
                        Positioned(
                          bottom: 0,
                          right: -5,
                          child: GestureDetector(
                            onTap: _pickUserProfileImage,
                            child: Material(
                              color: Colors.grey[50],
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Icon(
                                  Icons.edit,
                                  color: Theme.of(context).primaryColor,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${authState.firstName} ${authState.lastName}",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      authState.userEmail,
                      style: TextStyle(color: Colors.grey[800], fontSize: 12),
                    )
                  ],
                ),
              ),
              ListTile(
                tileColor: Colors.grey[100],
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.black54,
                ),
                title: const Text(
                  "profile_drawer_sign_out",
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ).tr(),
                onTap: () async {
                  bool res =
                      await ref.watch(authenticationProvider.notifier).logout();

                  if (res) {
                    ref.watch(backupProvider.notifier).cancelBackup();
                    ref.watch(assetProvider.notifier).clearAllAsset();
                    ref.watch(websocketProvider.notifier).disconnect();
                    // AutoRouter.of(context).popUntilRoot();
                    GoRouter.of(context).go('login');
                  }
                },
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 0,
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5), // if you need this
                side: const BorderSide(
                  color: Color.fromARGB(101, 201, 201, 201),
                  width: 1,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        serverInfoState.isVersionMismatch
                            ? serverInfoState.versionMismatchErrorMessage
                            : "profile_drawer_client_server_up_to_date".tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "App Version",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${appInfo.value["version"]} build.${appInfo.value["buildNumber"]}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Server Version",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${serverInfoState.serverVersion.major}.${serverInfoState.serverVersion.minor}.${serverInfoState.serverVersion.patch}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
