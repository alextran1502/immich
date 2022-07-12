import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/shared/ui/immich_loading_indicator.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumPreviewPage extends HookConsumerWidget {
  final AssetPathEntity album;
  const AlbumPreviewPage({Key? key, required this.album}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = useState<List<AssetEntity>>([]);

    _getAssetsInAlbum() async {
      assets.value =
          await album.getAssetListRange(start: 0, end: album.assetCount);
    }

    useEffect(() {
      _getAssetsInAlbum();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          children: [
            Text(
              "${album.name} (${album.assetCount})",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "ID ${album.id}",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: GoRouter.of(context).pop,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: assets.value.length,
        itemBuilder: (context, index) {
          Future<Uint8List?> thumbData = assets.value[index]
              .thumbnailDataWithSize(const ThumbnailSize(200, 200),
                  quality: 50);

          return FutureBuilder<Uint8List?>(
            future: thumbData,
            builder: ((context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                );
              }

              return const SizedBox(
                width: 100,
                height: 100,
                child: ImmichLoadingIndicator(),
              );
            }),
          );
        },
      ),
    );
  }
}
