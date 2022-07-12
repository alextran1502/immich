import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:chewie/chewie.dart';
import 'package:immich_mobile/modules/asset_viewer/models/image_viewer_page_state.model.dart';
import 'package:immich_mobile/modules/asset_viewer/providers/image_viewer_page_state.provider.dart';
import 'package:immich_mobile/modules/asset_viewer/ui/download_loading_indicator.dart';
import 'package:immich_mobile/modules/asset_viewer/ui/exif_bottom_sheet.dart';
import 'package:immich_mobile/modules/asset_viewer/ui/top_control_app_bar.dart';
import 'package:immich_mobile/modules/home/services/asset.service.dart';
import 'package:immich_mobile/shared/models/immich_asset.model.dart';
import 'package:immich_mobile/shared/models/immich_asset_with_exif.model.dart';
import 'package:video_player/video_player.dart';

// ignore: must_be_immutable
class VideoViewerPage extends HookConsumerWidget {
  final String videoUrl;
  final ImmichAsset asset;
  ImmichAssetWithExif? assetDetail;

  VideoViewerPage({Key? key, required this.videoUrl, required this.asset})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadAssetStatus =
        ref.watch(imageViewerStateProvider).downloadAssetStatus;

    String jwtToken = Hive.box(userInfoBox).get(accessTokenKey);

    void showInfo() {
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

    getAssetExif() async {
      assetDetail =
          await ref.watch(assetServiceProvider).getAssetById(asset.id);
    }

    useEffect(() {
      getAssetExif();
      return null;
    }, []);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: TopControlAppBar(
        asset: asset,
        onMoreInfoPressed: () {
          showInfo();
        },
        onDownloadPressed: () {
          ref
              .watch(imageViewerStateProvider.notifier)
              .downloadAsset(asset, context);
        },
      ),
      body: SwipeDetector(
        onSwipeDown: (_) => GoRouter.of(context).pop(),
        onSwipeUp: (_) {
          showInfo();
        },
        child: SafeArea(
          child: Stack(
            children: [
              VideoThumbnailPlayer(
                url: videoUrl,
                jwtToken: jwtToken,
              ),
              if (downloadAssetStatus == DownloadAssetStatus.loading)
                const Center(
                  child: DownloadLoadingIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoThumbnailPlayer extends StatefulWidget {
  final String url;
  final String? jwtToken;

  const VideoThumbnailPlayer({Key? key, required this.url, this.jwtToken})
      : super(key: key);

  @override
  State<VideoThumbnailPlayer> createState() => _VideoThumbnailPlayerState();
}

class _VideoThumbnailPlayerState extends State<VideoThumbnailPlayer> {
  late VideoPlayerController videoPlayerController;
  ChewieController? chewieController;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    try {
      videoPlayerController = VideoPlayerController.network(widget.url,
          httpHeaders: {"Authorization": "Bearer ${widget.jwtToken}"});

      await videoPlayerController.initialize();
      _createChewieController();
      setState(() {});
    } catch (e) {
      debugPrint("ERROR initialize video player");
    }
  }

  _createChewieController() {
    chewieController = ChewieController(
      showOptions: true,
      showControlsOnInitialize: false,
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      autoInitialize: false,
    );
  }

  @override
  void dispose() {
    super.dispose();
    videoPlayerController.pause();
    videoPlayerController.dispose();
    chewieController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return chewieController?.videoPlayerController.value.isInitialized == true
        ? SizedBox(
            child: Chewie(
              controller: chewieController!,
            ),
          )
        : const SizedBox(
            width: 75,
            height: 75,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 2,
            ),
          );
  }
}
