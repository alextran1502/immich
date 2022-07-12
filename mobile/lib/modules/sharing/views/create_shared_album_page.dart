import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/sharing/providers/album_title.provider.dart';
import 'package:immich_mobile/modules/sharing/providers/asset_selection.provider.dart';
import 'package:immich_mobile/modules/sharing/ui/album_action_outlined_button.dart';
import 'package:immich_mobile/modules/sharing/ui/album_title_text_field.dart';
import 'package:immich_mobile/modules/sharing/ui/shared_album_thumbnail_image.dart';
import 'package:immich_mobile/routing/router.dart';

class CreateSharedAlbumPage extends HookConsumerWidget {
  const CreateSharedAlbumPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumTitleController =
        useTextEditingController.fromValue(TextEditingValue.empty);
    final albumTitleTextFieldFocusNode = useFocusNode();
    final isAlbumTitleTextFieldFocus = useState(false);
    final isAlbumTitleEmpty = useState(true);
    final selectedAssets =
        ref.watch(assetSelectionProvider).selectedNewAssetsForAlbum;

    void _onBackgroundTapped() {
      albumTitleTextFieldFocusNode.unfocus();
      isAlbumTitleTextFieldFocus.value = false;

      if (albumTitleController.text.isEmpty) {
        albumTitleController.text = 'Untitled';
        ref.watch(albumTitleProvider.notifier).setAlbumTitle('Untitled');
      }
    }

    _onSelectPhotosButtonPressed() {
      ref.watch(assetSelectionProvider.notifier).setIsAlbumExist(false);

      GoRouter.of(context).pushNamed('${ImmichRoute.assetSelection}');

      // if (selectedAsset == null) {
      //   ref.watch(assetSelectionProvider.notifier).removeAll();
      // }
    }

    _buildTitleInputField() {
      return Padding(
        padding: const EdgeInsets.only(
          right: 10,
          left: 10,
        ),
        child: AlbumTitleTextField(
            isAlbumTitleEmpty: isAlbumTitleEmpty,
            albumTitleTextFieldFocusNode: albumTitleTextFieldFocusNode,
            albumTitleController: albumTitleController,
            isAlbumTitleTextFieldFocus: isAlbumTitleTextFieldFocus),
      );
    }

    _buildTitle() {
      if (selectedAssets.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 200, left: 18),
            child: Text(
              'create_shared_album_page_share_add_assets',
              style: TextStyle(fontSize: 12),
            ).tr(),
          ),
        );
      }

      return const SliverToBoxAdapter();
    }

    _buildSelectPhotosButton() {
      if (selectedAssets.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, left: 18, right: 18),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  side: const BorderSide(
                      color: Color.fromARGB(255, 206, 206, 206)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5))),
              onPressed: _onSelectPhotosButtonPressed,
              icon: const Icon(Icons.add_rounded),
              label: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'create_shared_album_page_share_select_photos',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold),
                ).tr(),
              ),
            ),
          ),
        );
      }

      return const SliverToBoxAdapter();
    }

    _buildControlButton() {
      return Padding(
        padding: const EdgeInsets.only(left: 12.0, top: 16, bottom: 16),
        child: SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              AlbumActionOutlinedButton(
                iconData: Icons.add_photo_alternate_outlined,
                onPressed: _onSelectPhotosButtonPressed,
                labelText: "share_add_photos".tr(),
              ),
            ],
          ),
        ),
      );
    }

    _buildSelectedImageGrid() {
      if (selectedAssets.isNotEmpty) {
        return SliverPadding(
          padding: const EdgeInsets.only(top: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 5,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return GestureDetector(
                  onTap: _onBackgroundTapped,
                  child: SharedAlbumThumbnailImage(
                      asset: selectedAssets.toList()[index]),
                );
              },
              childCount: selectedAssets.length,
            ),
          ),
        );
      }

      return const SliverToBoxAdapter();
    }

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
              onPressed: () {
                ref.watch(assetSelectionProvider.notifier).removeAll();
                GoRouter.of(context).pop();
              },
              icon: const Icon(Icons.close_rounded)),
          title: const Text(
            'share_create_album',
            style: TextStyle(color: Colors.black),
          ).tr(),
          actions: [
            TextButton(
              onPressed: albumTitleController.text.isNotEmpty
                  ? () => GoRouter.of(context)
                      .pushNamed('${ImmichRoute.selectUserForSharing}')
                  : null,
              child: Text(
                'create_shared_album_page_share'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: _onBackgroundTapped,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                elevation: 5,
                automaticallyImplyLeading: false,
                // leading: Container(),
                pinned: true,
                floating: false,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(66.0),
                  child: Column(
                    children: [
                      _buildTitleInputField(),
                      if (selectedAssets.isNotEmpty) _buildControlButton(),
                    ],
                  ),
                ),
              ),
              _buildTitle(),
              _buildSelectPhotosButton(),
              _buildSelectedImageGrid(),
            ],
          ),
        ));
  }
}
