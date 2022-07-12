import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/immich_colors.dart';
import 'package:immich_mobile/modules/sharing/models/shared_album.model.dart';
import 'package:immich_mobile/modules/sharing/providers/album_viewer.provider.dart';
import 'package:immich_mobile/modules/sharing/providers/asset_selection.provider.dart';
import 'package:immich_mobile/modules/sharing/providers/shared_album.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/shared/ui/immich_toast.dart';
import 'package:immich_mobile/shared/views/immich_loading_overlay.dart';

class AlbumViewerAppbar extends HookConsumerWidget with PreferredSizeWidget {
  const AlbumViewerAppbar({
    Key? key,
    required AsyncValue<SharedAlbum> albumInfo,
    required this.userId,
    required this.albumId,
  })  : _albumInfo = albumInfo,
        super(key: key);

  final AsyncValue<SharedAlbum> _albumInfo;
  final String userId;
  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMultiSelectionEnable =
        ref.watch(assetSelectionProvider).isMultiselectEnable;
    final selectedAssetsInAlbum =
        ref.watch(assetSelectionProvider).selectedAssetsInAlbumViewer;
    final newAlbumTitle = ref.watch(albumViewerProvider).editTitleText;
    final isEditAlbum = ref.watch(albumViewerProvider).isEditAlbum;

    void _onDeleteAlbumPressed(String albumId) async {
      ImmichLoadingOverlayController.appLoader.show();

      bool isSuccess =
          await ref.watch(sharedAlbumProvider.notifier).deleteAlbum(albumId);

      if (isSuccess) {
        GoRouter.of(context).goNamed('${ImmichRoute.sharing}');
      } else {
        ImmichToast.show(
          context: context,
          msg: "album_viewer_appbar_share_err_delete".tr(),
          toastType: ToastType.error,
          gravity: ToastGravity.BOTTOM,
        );
      }

      ImmichLoadingOverlayController.appLoader.hide();
    }

    void _onLeaveAlbumPressed(String albumId) async {
      ImmichLoadingOverlayController.appLoader.show();

      bool isSuccess =
          await ref.watch(sharedAlbumProvider.notifier).leaveAlbum(albumId);

      if (isSuccess) {
        GoRouter.of(context).goNamed('${ImmichRoute.sharing}');
      } else {
        Navigator.pop(context);
        ImmichToast.show(
          context: context,
          msg: "album_viewer_appbar_share_err_leave".tr(),
          toastType: ToastType.error,
          gravity: ToastGravity.BOTTOM,
        );
      }

      ImmichLoadingOverlayController.appLoader.hide();
    }

    void _onRemoveFromAlbumPressed(String albumId) async {
      ImmichLoadingOverlayController.appLoader.show();

      bool isSuccess =
          await ref.watch(sharedAlbumProvider.notifier).removeAssetFromAlbum(
                albumId,
                selectedAssetsInAlbum.map((a) => a.id).toList(),
              );

      if (isSuccess) {
        Navigator.pop(context);
        ref.watch(assetSelectionProvider.notifier).disableMultiselection();
        ref.refresh(sharedAlbumDetailProvider(albumId));
      } else {
        Navigator.pop(context);
        ImmichToast.show(
          context: context,
          msg: "album_viewer_appbar_share_err_remove".tr(),
          toastType: ToastType.error,
          gravity: ToastGravity.BOTTOM,
        );
      }

      ImmichLoadingOverlayController.appLoader.hide();
    }

    _buildBottomSheetActionButton() {
      if (isMultiSelectionEnable) {
        if (_albumInfo.asData?.value.ownerId == userId) {
          return ListTile(
            leading: const Icon(Icons.delete_sweep_rounded),
            title: const Text(
              'album_viewer_appbar_share_remove',
              style: TextStyle(fontWeight: FontWeight.bold),
            ).tr(),
            onTap: () => _onRemoveFromAlbumPressed(albumId),
          );
        } else {
          return const SizedBox();
        }
      } else {
        if (_albumInfo.asData?.value.ownerId == userId) {
          return ListTile(
            leading: const Icon(Icons.delete_forever_rounded),
            title: const Text(
              'album_viewer_appbar_share_delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ).tr(),
            onTap: () => _onDeleteAlbumPressed(albumId),
          );
        } else {
          return ListTile(
            leading: const Icon(Icons.person_remove_rounded),
            title: const Text(
              'album_viewer_appbar_share_leave',
              style: TextStyle(fontWeight: FontWeight.bold),
            ).tr(),
            onTap: () => _onLeaveAlbumPressed(albumId),
          );
        }
      }
    }

    void _buildBottomSheet() {
      showModalBottomSheet(
        backgroundColor: immichBackgroundColor,
        isScrollControlled: false,
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomSheetActionButton(),
              ],
            ),
          );
        },
      );
    }

    _buildLeadingButton() {
      if (isMultiSelectionEnable) {
        return IconButton(
          onPressed: () => ref
              .watch(assetSelectionProvider.notifier)
              .disableMultiselection(),
          icon: const Icon(Icons.close_rounded),
          splashRadius: 25,
        );
      } else if (isEditAlbum) {
        return IconButton(
          onPressed: () async {
            bool isSuccess = await ref
                .watch(albumViewerProvider.notifier)
                .changeAlbumTitle(albumId, userId, newAlbumTitle);

            if (!isSuccess) {
              ImmichToast.show(
                context: context,
                msg: "album_viewer_appbar_share_err_title".tr(),
                gravity: ToastGravity.BOTTOM,
                toastType: ToastType.error,
              );
            }
          },
          icon: const Icon(Icons.check_rounded),
          splashRadius: 25,
        );
      } else {
        return IconButton(
          onPressed: GoRouter.of(context).pop,
          icon: const Icon(Icons.arrow_back_ios_rounded),
          splashRadius: 25,
        );
      }
    }

    return AppBar(
      elevation: 0,
      leading: _buildLeadingButton(),
      title: isMultiSelectionEnable
          ? Text('${selectedAssetsInAlbum.length}')
          : null,
      centerTitle: false,
      actions: [
        IconButton(
          splashRadius: 25,
          onPressed: _buildBottomSheet,
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
