import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/immich_colors.dart';
import 'package:immich_mobile/modules/home/ui/draggable_scrollbar.dart';
import 'package:immich_mobile/modules/login/providers/authentication.provider.dart';
import 'package:immich_mobile/modules/sharing/models/shared_album.model.dart';
import 'package:immich_mobile/modules/sharing/providers/asset_selection.provider.dart';
import 'package:immich_mobile/modules/sharing/providers/shared_album.provider.dart';
import 'package:immich_mobile/modules/sharing/ui/album_action_outlined_button.dart';
import 'package:immich_mobile/modules/sharing/ui/album_viewer_appbar.dart';
import 'package:immich_mobile/modules/sharing/ui/album_viewer_editable_title.dart';
import 'package:immich_mobile/modules/sharing/ui/album_viewer_thumbnail.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/shared/ui/immich_loading_indicator.dart';
import 'package:immich_mobile/shared/ui/immich_sliver_persistent_app_bar_delegate.dart';

class AlbumViewerPage extends HookConsumerWidget {
  final String albumId;

  const AlbumViewerPage({Key? key, required this.albumId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FocusNode titleFocusNode = useFocusNode();
    ScrollController scrollController = useScrollController();
    AsyncValue<SharedAlbum> albumInfo =
        ref.watch(sharedAlbumDetailProvider(albumId));

    final userId = ref.watch(authenticationProvider).userId;

    /// Find out if the assets in album exist on the device
    /// If they exist, add to selected asset state to show they are already selected.
    void _onAddPhotosPressed(SharedAlbum albumInfo) async {
      if (albumInfo.assets?.isNotEmpty == true) {
        ref
            .watch(assetSelectionProvider.notifier)
            .addNewAssets(albumInfo.assets!.toList());
      }

      ref.watch(assetSelectionProvider.notifier).setIsAlbumExist(true);

      GoRouter.of(context).pushNamed(
        '${ImmichRoute.assetSelection}',
        queryParams: {'albumId': albumId},
      );
    }

    void _onAddUsersPressed(SharedAlbum albumInfo) async {
      GoRouter.of(context).pushNamed(
        '${ImmichRoute.selectAdditionalUserForSharing}',
        extra: albumInfo,
      );
    }

    Widget _buildTitle(SharedAlbum albumInfo) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 16),
        child: userId == albumInfo.ownerId
            ? AlbumViewerEditableTitle(
                albumInfo: albumInfo,
                titleFocusNode: titleFocusNode,
              )
            : Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(albumInfo.albumName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ),
      );
    }

    Widget _buildAlbumDateRange(SharedAlbum albumInfo) {
      String startDate = "";
      DateTime parsedStartDate =
          DateTime.parse(albumInfo.assets!.first.createdAt);
      DateTime parsedEndDate = DateTime.parse(
          albumInfo.assets?.last.createdAt ?? '11111111'); //Need default.

      if (parsedStartDate.year == parsedEndDate.year) {
        startDate = DateFormat('LLL d').format(parsedStartDate);
      } else {
        startDate = DateFormat('LLL d, y').format(parsedStartDate);
      }

      String endDate = DateFormat('LLL d, y').format(parsedEndDate);

      return Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 8),
        child: Text(
          "$startDate-$endDate",
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    Widget _buildHeader(SharedAlbum albumInfo) {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(albumInfo),
            if (albumInfo.assets?.isNotEmpty == true)
              _buildAlbumDateRange(albumInfo),
            SizedBox(
              height: 60,
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: ((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      radius: 18,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50.0),
                          child:
                              Image.asset('assets/immich-logo-no-outline.png'),
                        ),
                      ),
                    ),
                  );
                }),
                itemCount: albumInfo.sharedUsers.length,
              ),
            )
          ],
        ),
      );
    }

    Widget _buildImageGrid(SharedAlbum albumInfo) {
      if (albumInfo.assets?.isNotEmpty == true) {
        return SliverPadding(
          padding: const EdgeInsets.only(top: 10.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 5,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return AlbumViewerThumbnail(asset: albumInfo.assets![index]);
              },
              childCount: albumInfo.assets?.length,
            ),
          ),
        );
      }
      return const SliverToBoxAdapter();
    }

    Widget _buildControlButton(SharedAlbum albumInfo) {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
        child: SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              AlbumActionOutlinedButton(
                iconData: Icons.add_photo_alternate_outlined,
                onPressed: () => _onAddPhotosPressed(albumInfo),
                labelText: "share_add_photos".tr(),
              ),
              if (userId == albumInfo.ownerId)
                AlbumActionOutlinedButton(
                  iconData: Icons.person_add_alt_rounded,
                  onPressed: () => _onAddUsersPressed(albumInfo),
                  labelText: "album_viewer_page_share_add_users".tr(),
                ),
            ],
          ),
        ),
      );
    }

    Widget _buildBody(SharedAlbum albumInfo) {
      return GestureDetector(
        onTap: () {
          titleFocusNode.unfocus();
        },
        child: DraggableScrollbar.semicircle(
          backgroundColor: Theme.of(context).primaryColor,
          controller: scrollController,
          heightScrollThumb: 48.0,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              _buildHeader(albumInfo),
              SliverPersistentHeader(
                pinned: true,
                delegate: ImmichSliverPersistentAppBarDelegate(
                  minHeight: 50,
                  maxHeight: 50,
                  child: Container(
                    color: immichBackgroundColor,
                    child: _buildControlButton(albumInfo),
                  ),
                ),
              ),
              _buildImageGrid(albumInfo)
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AlbumViewerAppbar(
          albumInfo: albumInfo, userId: userId, albumId: albumId),
      body: albumInfo.when(
        data: (albumInfo) => _buildBody(albumInfo),
        error: (e, _) => Center(child: Text("Error loading album info $e")),
        loading: () => const Center(
          child: ImmichLoadingIndicator(),
        ),
      ),
    );
  }
}
