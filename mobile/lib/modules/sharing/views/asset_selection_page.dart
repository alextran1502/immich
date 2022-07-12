import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/home/ui/draggable_scrollbar.dart';
import 'package:immich_mobile/modules/sharing/models/asset_selection_page_result.model.dart';
import 'package:immich_mobile/modules/sharing/providers/asset_selection.provider.dart';
import 'package:immich_mobile/modules/sharing/providers/shared_album.provider.dart';
import 'package:immich_mobile/modules/sharing/services/shared_album.service.dart';
import 'package:immich_mobile/modules/sharing/ui/asset_grid_by_month.dart';
import 'package:immich_mobile/modules/sharing/ui/month_group_title.dart';
import 'package:immich_mobile/shared/providers/asset.provider.dart';
import 'package:immich_mobile/shared/views/immich_loading_overlay.dart';

class AssetSelectionPage extends HookConsumerWidget {
  final String albumId;
  const AssetSelectionPage({Key? key, required this.albumId}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ScrollController scrollController = useScrollController();
    var assetGroupMonthYear = ref.watch(assetGroupByMonthYearProvider);
    final selectedAssets =
        ref.watch(assetSelectionProvider).selectedNewAssetsForAlbum;
    final newAssetsForAlbum =
        ref.watch(assetSelectionProvider).selectedAdditionalAssetsForAlbum;
    final isAlbumExist = ref.watch(assetSelectionProvider).isAlbumExist;

    List<Widget> imageGridGroup = [];

    String _buildAssetCountText() {
      if (isAlbumExist) {
        return (selectedAssets.length + newAssetsForAlbum.length).toString();
      } else {
        return selectedAssets.length.toString();
      }
    }

    Widget _buildBody() {
      assetGroupMonthYear.forEach((monthYear, assetGroup) {
        imageGridGroup
            .add(MonthGroupTitle(month: monthYear, assetGroup: assetGroup));
        imageGridGroup.add(AssetGridByMonth(assetGroup: assetGroup));
      });

      return Stack(
        children: [
          DraggableScrollbar.semicircle(
            backgroundColor: Theme.of(context).primaryColor,
            controller: scrollController,
            heightScrollThumb: 48.0,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [...imageGridGroup],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.watch(assetSelectionProvider.notifier).removeAll();
            GoRouter.of(context).pop();
          },
        ),
        title: selectedAssets.isEmpty
            ? const Text(
                'share_add_photos',
                style: TextStyle(fontSize: 18),
              ).tr()
            : Text(
                _buildAssetCountText(),
                style: const TextStyle(fontSize: 18),
              ),
        centerTitle: false,
        actions: [
          if ((!isAlbumExist && selectedAssets.isNotEmpty) ||
              (isAlbumExist && newAssetsForAlbum.isNotEmpty))
            TextButton(
              onPressed: () async {
                var payload = AssetSelectionPageResult(
                  isAlbumExist: isAlbumExist,
                  selectedAdditionalAsset: newAssetsForAlbum,
                  selectedNewAsset: selectedAssets,
                );

                if (payload.selectedAdditionalAsset.isNotEmpty) {
                  ImmichLoadingOverlayController.appLoader.show();

                  var isSuccess = await ref
                      .watch(sharedAlbumServiceProvider)
                      .addAdditionalAssetToAlbum(
                          payload.selectedAdditionalAsset, albumId);

                  if (isSuccess) {
                    ref.refresh(sharedAlbumDetailProvider(albumId));
                  }

                  ImmichLoadingOverlayController.appLoader.hide();
                }

                ref.watch(assetSelectionProvider.notifier).removeAll();

                GoRouter.of(context).pop();
              },
              child: const Text(
                "share_add",
                style: TextStyle(fontWeight: FontWeight.bold),
              ).tr(),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
