// import 'package:auto_route/auto_route.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';

// import 'package:immich_mobile/modules/search/providers/search_page_state.provider.dart';
// import 'package:immich_mobile/modules/sharing/providers/shared_album.provider.dart';
// import 'package:immich_mobile/shared/providers/server_info.provider.dart';

// class TabNavigationObserver extends AutoRouterObserver {
//   /// Riverpod Instance
//   final WidgetRef ref;

//   TabNavigationObserver({
//     required this.ref,
//   });

//   @override
//   void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {
//     // Perform tasks on first navigation to SearchRoute
//     if (route.name == 'SearchRoute') {
//       // ref.refresh(getCuratedLocationProvider);
//     }
//   }

//   @override
//   Future<void> didChangeTabRoute(
//       TabPageRoute route, TabPageRoute previousRoute) async {
//     // Perform tasks on re-visit to SearchRoute
//     if (route.name == 'SearchRoute') {
//       // Refresh Location State
//       ref.refresh(getCuratedLocationProvider);
//       ref.refresh(getCuratedObjectProvider);
//     }

//     if (route.name == 'SharingRoute') {
//       ref.read(sharedAlbumProvider.notifier).getAllSharedAlbums();
//     }

//     ref.watch(serverInfoProvider.notifier).getServerVersion();
//   }
// }
