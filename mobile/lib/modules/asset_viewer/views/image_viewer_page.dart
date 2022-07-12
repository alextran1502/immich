import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:immich_mobile/modules/asset_viewer/models/image_viewer_page_state.model.dart';
import 'package:immich_mobile/modules/asset_viewer/providers/image_viewer_page_state.provider.dart';
import 'package:immich_mobile/modules/asset_viewer/ui/download_loading_indicator.dart';
import 'package:immich_mobile/modules/asset_viewer/ui/exif_bottom_sheet.dart';
import 'package:immich_mobile/modules/asset_viewer/ui/remote_photo_view.dart';
import 'package:immich_mobile/modules/asset_viewer/ui/top_control_app_bar.dart';
import 'package:immich_mobile/modules/home/services/asset.service.dart';
import 'package:immich_mobile/shared/models/immich_asset.model.dart';
import 'package:immich_mobile/shared/models/immich_asset_with_exif.model.dart';

// ignore: must_be_immutable
class ImageViewerPage extends HookConsumerWidget {
  final String imageUrl;
  final String heroTag;
  final String thumbnailUrl;
  final ImmichAsset asset;

  ImmichAssetWithExif? assetDetail;

  ImageViewerPage({
    Key? key,
    required this.imageUrl,
    required this.heroTag,
    required this.thumbnailUrl,
    required this.asset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadAssetStatus =
        ref.watch(imageViewerStateProvider).downloadAssetStatus;
    var box = Hive.box(userInfoBox);

    getAssetExif() async {
      assetDetail =
          await ref.watch(assetServiceProvider).getAssetById(asset.id);
    }

    showInfo() {
      showModalBottomSheet(
        backgroundColor: Colors.black,
        barrierColor: Colors.transparent,
        isScrollControlled: false,
        context: context,
        builder: (context) {
          return ExifBottomSheet(assetDetail: assetDetail!);
        },
      );
    }

    useEffect(() {
      getAssetExif();
      return null;
    }, []);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: TopControlAppBar(
        asset: asset,
        onMoreInfoPressed: showInfo,
        onDownloadPressed: () {
          ref
              .watch(imageViewerStateProvider.notifier)
              .downloadAsset(asset, context);
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Hero(
                  tag: heroTag,
                  child: RemotePhotoView(
                    thumbnailUrl: thumbnailUrl,
                    imageUrl: imageUrl,
                    authToken: "Bearer ${box.get(accessTokenKey)}",
                    onSwipeDown: GoRouter.of(context).pop,
                    onSwipeUp: showInfo,
                  )),
            ),
            if (downloadAssetStatus == DownloadAssetStatus.loading)
              const Center(
                child: DownloadLoadingIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
