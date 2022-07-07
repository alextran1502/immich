import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:immich_mobile/constants/immich_colors.dart';
import 'package:immich_mobile/modules/backup/providers/backup.provider.dart';
import 'package:immich_mobile/modules/login/models/hive_saved_login_info.model.dart';
import 'package:immich_mobile/modules/login/providers/authentication.provider.dart';
import 'package:immich_mobile/modules/login/services/local_auth.service.dart';
import 'package:immich_mobile/modules/login/services/oauth2.service.dart';
import 'package:immich_mobile/routing/router.dart';

class SplashScreenPage extends HookConsumerWidget {
  const SplashScreenPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    HiveSavedLoginInfo? loginInfo =
        Hive.box<HiveSavedLoginInfo>(hiveLoginInfoBox).get(savedLoginInfoKey);

    void performLoggingIn() async {
      var isAuthenticated = await ref
          .read(authenticationProvider.notifier)
          .refreshLogin();

      if (isAuthenticated) {
        await ref.watch(authenticationProvider.notifier).finalizeLogin();
        // Resume backup (if enable) then navigate
        ref.watch(backupProvider.notifier).resumeBackup();
        AutoRouter.of(context).pushNamed("/tab-controller-page");
      } else {
        AutoRouter.of(context).push(const LoginRoute());
      }
    }

    useEffect(() {
      if (loginInfo?.isSaveLogin == true) {
        performLoggingIn();
      } else {
        AutoRouter.of(context).push(const LoginRoute());
      }
      return null;
    }, []);

    return Scaffold(
      backgroundColor: immichBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage('assets/immich-logo-no-outline.png'),
              width: 200,
              filterQuality: FilterQuality.high,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'IMMICH',
                style: TextStyle(
                  fontFamily: 'SnowburstOne',
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
