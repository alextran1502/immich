import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/backup/providers/backup.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/shared/ui/immich_toast.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumInfoCard extends HookConsumerWidget {
  final Uint8List? imageData;
  final AssetPathEntity albumInfo;

  const AlbumInfoCard({Key? key, this.imageData, required this.albumInfo})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelected =
        ref.watch(backupProvider).selectedBackupAlbums.contains(albumInfo);
    final bool isExcluded =
        ref.watch(backupProvider).excludedBackupAlbums.contains(albumInfo);

    ColorFilter selectedFilter = ColorFilter.mode(
        Theme.of(context).primaryColor.withAlpha(100), BlendMode.darken);
    ColorFilter excludedFilter =
        ColorFilter.mode(Colors.red.withAlpha(75), BlendMode.darken);
    ColorFilter unselectedFilter =
        const ColorFilter.mode(Colors.black, BlendMode.color);

    _buildSelectedTextBox() {
      if (isSelected) {
        return Chip(
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          label: const Text(
            "album_info_card_backup_album_included",
            style: TextStyle(
                fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
          ).tr(),
          backgroundColor: Theme.of(context).primaryColor,
        );
      } else if (isExcluded) {
        return Chip(
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          label: const Text(
            "album_info_card_backup_album_excluded",
            style: TextStyle(
                fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
          ).tr(),
          backgroundColor: Colors.red[300],
        );
      }

      return const SizedBox();
    }

    _buildImageFilter() {
      if (isSelected) {
        return selectedFilter;
      } else if (isExcluded) {
        return excludedFilter;
      } else {
        return unselectedFilter;
      }
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();

        if (isSelected) {
          if (ref.watch(backupProvider).selectedBackupAlbums.length == 1) {
            ImmichToast.show(
              context: context,
              msg: "backup_err_only_album".tr(),
              toastType: ToastType.error,
              gravity: ToastGravity.BOTTOM,
            );
            return;
          }

          ref.watch(backupProvider.notifier).removeAlbumForBackup(albumInfo);
        } else {
          ref.watch(backupProvider.notifier).addAlbumForBackup(albumInfo);
        }
      },
      onDoubleTap: () {
        HapticFeedback.selectionClick();

        if (isExcluded) {
          ref
              .watch(backupProvider.notifier)
              .removeExcludedAlbumForBackup(albumInfo);
        } else {
          if (ref.watch(backupProvider).selectedBackupAlbums.length == 1 &&
              ref
                  .watch(backupProvider)
                  .selectedBackupAlbums
                  .contains(albumInfo)) {
            ImmichToast.show(
              context: context,
              msg: "backup_err_only_album".tr(),
              toastType: ToastType.error,
              gravity: ToastGravity.BOTTOM,
            );
            return;
          }

          ref
              .watch(backupProvider.notifier)
              .addExcludedAlbumForBackup(albumInfo);
        }
      },
      child: Card(
        margin: const EdgeInsets.all(1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // if you need this
          side: const BorderSide(
            color: Color(0xFFC9C9C9),
            width: 1,
          ),
        ),
        elevation: 0,
        borderOnForeground: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)),
                    image: DecorationImage(
                      colorFilter: _buildImageFilter(),
                      image: imageData != null
                          ? MemoryImage(imageData!)
                          : const AssetImage(
                                  'assets/immich-logo-no-outline.png')
                              as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: null,
                ),
                Positioned(
                  bottom: 10,
                  left: 25,
                  child: _buildSelectedTextBox(),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            albumInfo.name,
                            style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              albumInfo.assetCount.toString() +
                                  (albumInfo.isAll
                                      ? " (${'backup_all'.tr()})"
                                      : ""),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => GoRouter.of(context).pushNamed(
                        '${ImmichRoute.albumPreview}',
                        extra: albumInfo),
                    icon: Icon(
                      Icons.image_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    splashRadius: 25,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
