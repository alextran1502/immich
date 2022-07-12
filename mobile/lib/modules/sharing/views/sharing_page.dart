import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:immich_mobile/modules/sharing/models/shared_album.model.dart';
import 'package:immich_mobile/modules/sharing/providers/shared_album.provider.dart';
import 'package:immich_mobile/modules/sharing/ui/sharing_sliver_appbar.dart';
import 'package:immich_mobile/routing/router.dart';

import 'package:transparent_image/transparent_image.dart';

class SharingPage extends HookConsumerWidget {
  const SharingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var box = Hive.box(userInfoBox);
    var thumbnailRequestUrl = '${box.get(serverEndpointKey)}/asset/thumbnail';
    final List<SharedAlbum> sharedAlbums = ref.watch(sharedAlbumProvider);

    useEffect(() {
      ref.read(sharedAlbumProvider.notifier).getAllSharedAlbums();

      return null;
    }, []);

    _buildAlbumList() {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            String thumbnailUrl = sharedAlbums[index].albumThumbnailAssetId !=
                    null
                ? "$thumbnailRequestUrl/${sharedAlbums[index].albumThumbnailAssetId}"
                : "https://images.unsplash.com/photo-1612178537253-bccd437b730e?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NXx8Ymxhbmt8ZW58MHx8MHx8&auto=format&fit=crop&w=700&q=60";

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FadeInImage(
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: MemoryImage(kTransparentImage),
                  image: NetworkImage(
                    thumbnailUrl,
                    headers: {
                      "Authorization": "Bearer ${box.get(accessTokenKey)}"
                    },
                  ),
                  fadeInDuration: const Duration(milliseconds: 200),
                  fadeOutDuration: const Duration(milliseconds: 200),
                ),
              ),
              title: Text(
                sharedAlbums[index].albumName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800),
              ),
              onTap: () {
                GoRouter.of(context).pushNamed(
                  '${ImmichRoute.albumViewer}',
                  queryParams: {
                    'albumId': sharedAlbums[index].id,
                  },
                );
              },
            );
          },
          childCount: sharedAlbums.length,
        ),
      );
    }

    _buildEmptyListIndication() {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // if you need this
              side: const BorderSide(
                color: Colors.black12,
                width: 1,
              ),
            ),
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0, bottom: 5),
                    child: Icon(
                      Icons.offline_share_outlined,
                      size: 50,
                      color: Theme.of(context).primaryColor.withAlpha(200),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'sharing_page_empty_list',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ).tr(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'sharing_page_description',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ).tr(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SharingSliverAppBar(),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                "sharing_page_album",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ).tr(),
            ),
          ),
          sharedAlbums.isNotEmpty
              ? _buildAlbumList()
              : _buildEmptyListIndication()
        ],
      ),
    );
  }
}
