import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/asset_viewer/views/image_viewer_page.dart';
import 'package:immich_mobile/modules/asset_viewer/views/video_viewer_page.dart';
import 'package:immich_mobile/modules/backup/views/album_preview_page.dart';
import 'package:immich_mobile/modules/backup/views/backup_album_selection_page.dart';
import 'package:immich_mobile/modules/backup/views/backup_controller_page.dart';
import 'package:immich_mobile/modules/backup/views/failed_backup_status_page.dart';
import 'package:immich_mobile/modules/home/views/home_page.dart';
import 'package:immich_mobile/modules/login/providers/authentication.provider.dart';
import 'package:immich_mobile/modules/login/views/change_password_page.dart';
import 'package:immich_mobile/modules/login/views/login_page.dart';
import 'package:immich_mobile/modules/search/views/search_result_page.dart';
import 'package:immich_mobile/modules/sharing/models/shared_album.model.dart';
import 'package:immich_mobile/modules/sharing/views/album_viewer_page.dart';
import 'package:immich_mobile/modules/sharing/views/asset_selection_page.dart';
import 'package:immich_mobile/modules/sharing/views/create_shared_album_page.dart';
import 'package:immich_mobile/modules/sharing/views/select_additional_user_for_sharing_page.dart';
import 'package:immich_mobile/modules/sharing/views/select_user_for_sharing_page.dart';
import 'package:immich_mobile/shared/models/immich_asset.model.dart';
import 'package:immich_mobile/shared/views/splash_screen.dart';
import 'package:immich_mobile/utils/camel_to_kebab.dart';
import 'package:photo_manager/photo_manager.dart';

///ref: https://github.com/lucavenir/go_router_riverpod

final routerProvider = Provider<GoRouter>(
  (ref) {
    final router = RouterNotifier(ref);

    return GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: kDebugMode,
      refreshListenable: router,
      redirect: router._redirectLogic,
      routes: router._routes,
    );
  },
);

enum ImmichRoute {
  home,
  photos(tabIndex: 0),
  search(tabIndex: 1),
  sharing(tabIndex: 2),
  login,
  splash,
  changePassword,
  imageViewer,
  videoViewer,
  backupController,
  backupAlbumSelection,
  albumPreview,
  createSharedAlbum,
  selectUserForSharing,
  searchResult,
  assetSelection,
  albumViewer,
  selectAdditionalUserForSharing,
  failedBackupStatus;

  final int tabIndex;

  const ImmichRoute({this.tabIndex = -1});

  @override
  String toString() => name.camelTokebab();
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(
      authenticationProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? _redirectLogic(GoRouterState state) {
    var isAuthenticated = _ref.read(authenticationProvider).isAuthenticated;
    final finishLoggedIn =
        state.location == '/splash' || state.location == '/login';

    if (!isAuthenticated) return finishLoggedIn ? null : '/login';

    if (finishLoggedIn) return '/';

    return null;
  }

  List<GoRoute> get _routes => [
        GoRoute(
          name: '${ImmichRoute.home}',
          path: '/',
          redirect: (state) {
            var selectedTab = state.extra;

            return selectedTab is ImmichRoute && selectedTab.tabIndex > 0
                ? state.namedLocation('$selectedTab')
                : state.namedLocation('${ImmichRoute.photos}');
          },
          routes: [
            for (var tab
                in ImmichRoute.values.where((element) => element.tabIndex >= 0))
              GoRoute(
                name: tab.name,
                path: tab.name,
                pageBuilder: (_, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: HomePage(
                    initTabIndex: tab.tabIndex,
                  ),
                ),
              ),
            GoRoute(
              name: '${ImmichRoute.login}',
              path: '${ImmichRoute.login}',
              builder: (_, __) => const LoginPage(),
            ),
            GoRoute(
              name: '${ImmichRoute.splash}',
              path: '${ImmichRoute.splash}',
              builder: (_, __) => const SplashScreenPage(),
            ),
            GoRoute(
              name: '${ImmichRoute.changePassword}',
              path: '${ImmichRoute.changePassword}',
              builder: (_, __) => const ChangePasswordPage(),
            ),
            GoRoute(
              name: '${ImmichRoute.imageViewer}',
              path: '${ImmichRoute.imageViewer}',
              builder: (_, state) => ImageViewerPage(
                imageUrl: state.queryParams['imageUrl']!,
                heroTag: state.queryParams['heroTag']!,
                thumbnailUrl: state.queryParams['thumbnailUrl']!,
                asset: state.extra as ImmichAsset,
              ),
            ),
            GoRoute(
              name: '${ImmichRoute.videoViewer}',
              path: '${ImmichRoute.videoViewer}',
              builder: (_, state) => VideoViewerPage(
                videoUrl: state.queryParams['videoUrl']!,
                asset: state.extra as ImmichAsset,
              ),
            ),
            GoRoute(
              name: '${ImmichRoute.backupController}',
              path: '${ImmichRoute.backupController}',
              builder: (_, __) => const BackupControllerPage(),
            ),
            GoRoute(
              name: '${ImmichRoute.backupAlbumSelection}',
              path: '${ImmichRoute.backupAlbumSelection}',
              builder: (_, __) => const BackupAlbumSelectionPage(),
            ),
            GoRoute(
              name: '${ImmichRoute.albumPreview}',
              path: '${ImmichRoute.albumPreview}',
              builder: (_, state) => AlbumPreviewPage(
                album: state.extra as AssetPathEntity,
              ),
            ),
            GoRoute(
              name: '${ImmichRoute.createSharedAlbum}',
              path: '${ImmichRoute.createSharedAlbum}',
              builder: (_, __) => const CreateSharedAlbumPage(),
            ),
            GoRoute(
              name: '${ImmichRoute.selectUserForSharing}',
              path: '${ImmichRoute.selectUserForSharing}',
              builder: (_, __) => const SelectUserForSharingPage(),
            ),
            GoRoute(
              name: '${ImmichRoute.searchResult}',
              path: '${ImmichRoute.searchResult}',
              builder: (_, state) => SearchResultPage(
                searchTerm: state.queryParams['searchTerm'] ?? '',
              ),
            ),
            GoRoute(
              name: '${ImmichRoute.assetSelection}',
              path: '${ImmichRoute.assetSelection}',
              builder: (_, state) => AssetSelectionPage(
                albumId: state.queryParams['albumId'] ?? '',
              ),
            ),
            GoRoute(
              name: '${ImmichRoute.albumViewer}',
              path: '${ImmichRoute.albumViewer}',
              builder: (_, state) => AlbumViewerPage(
                albumId: state.queryParams['albumId'] ?? '',
              ),
            ),
            GoRoute(
              name: '${ImmichRoute.selectAdditionalUserForSharing}',
              path: '${ImmichRoute.selectAdditionalUserForSharing}',
              builder: (_, state) => SelectAdditionalUserForSharingPage(
                albumInfo: state.extra! as SharedAlbum,
              ),
            ),
            GoRoute(
              name: '${ImmichRoute.failedBackupStatus}',
              path: '${ImmichRoute.failedBackupStatus}',
              builder: (_, __) => const FailedBackupStatusPage(),
            ),
          ],
        ),
      ];
}
