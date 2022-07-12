import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/immich_colors.dart';
import 'package:immich_mobile/modules/backup/models/hive_backup_albums.model.dart';
import 'package:immich_mobile/modules/backup/providers/backup.provider.dart';
import 'package:immich_mobile/modules/login/models/hive_saved_login_info.model.dart';
import 'package:immich_mobile/modules/login/providers/authentication.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/shared/providers/app_state.provider.dart';
import 'package:immich_mobile/shared/providers/asset.provider.dart';
import 'package:immich_mobile/shared/providers/release_info.provider.dart';
import 'package:immich_mobile/shared/providers/server_info.provider.dart';
import 'package:immich_mobile/shared/providers/websocket.provider.dart';
import 'package:immich_mobile/shared/views/immich_loading_overlay.dart';
import 'package:immich_mobile/shared/views/version_announcement_overlay.dart';

import 'constants/hive_box.dart';

void main() async {
  await Hive.initFlutter();

  Hive.registerAdapter(HiveSavedLoginInfoAdapter());
  Hive.registerAdapter(HiveBackupAlbumsAdapter());

  await Hive.openBox(userInfoBox);
  await Hive.openBox<HiveSavedLoginInfo>(hiveLoginInfoBox);
  await Hive.openBox<HiveBackupAlbums>(hiveBackupInfoBox);
  await Hive.openBox(hiveGithubReleaseInfoBox);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await EasyLocalization.ensureInitialized();

  var locales = const [
    // Default locale
    Locale('en', 'US'),
    // Additional locales
    Locale('de', 'DE')
  ];

  runApp(EasyLocalization(
      supportedLocales: locales,
      path: 'assets/i18n',
      useFallbackTranslations: true,
      fallbackLocale: locales.first,
      child: const ProviderScope(child: ImmichApp())));
}

class ImmichApp extends HookConsumerWidget {
  const ImmichApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useOnAppLifecycleStateChange(
      (previous, current) {
        switch (current) {
          case AppLifecycleState.resumed:
            debugPrint("[APP STATE] resumed");
            ref.watch(appStateProvider.notifier).state = AppStateEnum.resumed;

            var isAuthenticated =
                ref.watch(authenticationProvider).isAuthenticated;

            if (isAuthenticated) {
              ref.watch(backupProvider.notifier).resumeBackup();
              ref.watch(assetProvider.notifier).getAllAsset();
              ref.watch(serverInfoProvider.notifier).getServerVersion();
            }

            ref.watch(websocketProvider.notifier).connect();
            ref.watch(releaseInfoProvider.notifier).checkGithubReleaseInfo();

            break;

          case AppLifecycleState.inactive:
            debugPrint("[APP STATE] inactive");
            ref.watch(appStateProvider.notifier).state = AppStateEnum.inactive;
            ref.watch(websocketProvider.notifier).disconnect();
            ref.watch(backupProvider.notifier).cancelBackup();

            break;

          case AppLifecycleState.paused:
            debugPrint("[APP STATE] paused");
            ref.watch(appStateProvider.notifier).state = AppStateEnum.paused;
            break;

          case AppLifecycleState.detached:
            debugPrint("[APP STATE] detached");
            ref.watch(appStateProvider.notifier).state = AppStateEnum.detached;
            break;
          default:
        }
      },
    );

    final router = ref.watch(routerProvider);
    useEffect(() {
      ref.watch(releaseInfoProvider.notifier).checkGithubReleaseInfo();
      return null;
    }, []);

    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      home: Stack(
        children: [
          MaterialApp.router(
            title: 'Immich',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              primarySwatch: Colors.indigo,
              fontFamily: 'WorkSans',
              snackBarTheme: const SnackBarThemeData(
                  contentTextStyle: TextStyle(fontFamily: 'WorkSans')),
              scaffoldBackgroundColor: immichBackgroundColor,
              appBarTheme: const AppBarTheme(
                backgroundColor: immichBackgroundColor,
                foregroundColor: Colors.indigo,
                elevation: 1,
                centerTitle: true,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
              ),
            ),
            routeInformationProvider: router.routeInformationProvider,
            routeInformationParser: router.routeInformationParser,
            routerDelegate: router.routerDelegate,
          ),
          const ImmichLoadingOverlay(),
          const VersionAnnouncementOverlay(),
        ],
      ),
    );
  }
}
