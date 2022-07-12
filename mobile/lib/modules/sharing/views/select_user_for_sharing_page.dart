import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/sharing/providers/album_title.provider.dart';
import 'package:immich_mobile/modules/sharing/providers/asset_selection.provider.dart';
import 'package:immich_mobile/modules/sharing/providers/shared_album.provider.dart';
import 'package:immich_mobile/modules/sharing/providers/suggested_shared_users.provider.dart';
import 'package:immich_mobile/modules/sharing/services/shared_album.service.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/shared/models/user.model.dart';
import 'package:immich_mobile/shared/ui/immich_loading_indicator.dart';

class SelectUserForSharingPage extends HookConsumerWidget {
  const SelectUserForSharingPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedUsersList = useState<Set<User>>({});
    AsyncValue<List<User>> suggestedShareUsers =
        ref.watch(suggestedSharedUsersProvider);

    _createSharedAlbum() async {
      var isSuccess =
          await ref.watch(sharedAlbumServiceProvider).createSharedAlbum(
                ref.watch(albumTitleProvider),
                ref.watch(assetSelectionProvider).selectedNewAssetsForAlbum,
                sharedUsersList.value.map((userInfo) => userInfo.id).toList(),
              );

      if (isSuccess) {
        await ref.watch(sharedAlbumProvider.notifier).getAllSharedAlbums();
        ref.watch(assetSelectionProvider.notifier).removeAll();
        ref.watch(albumTitleProvider.notifier).clearAlbumTitle();

        GoRouter.of(context).goNamed('${ImmichRoute.sharing}');
      }

      ScaffoldMessenger(
          child: SnackBar(
              content: Text('select_user_for_sharing_page_err_album').tr()));
    }

    _buildTileIcon(User user) {
      if (sharedUsersList.value.contains(user)) {
        return CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(
            Icons.check_rounded,
            size: 25,
          ),
        );
      } else {
        return CircleAvatar(
          backgroundImage:
              const AssetImage('assets/immich-logo-no-outline.png'),
          backgroundColor: Theme.of(context).primaryColor.withAlpha(50),
        );
      }
    }

    _buildUserList(List<User> users) {
      List<Widget> usersChip = [];

      for (var user in sharedUsersList.value) {
        usersChip.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Chip(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
              label: Text(
                user.email,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            children: [...usersChip],
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'share_suggestions',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold),
            ).tr(),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemBuilder: ((context, index) {
              return ListTile(
                leading: _buildTileIcon(users[index]),
                title: Text(
                  users[index].email,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  if (sharedUsersList.value.contains(users[index])) {
                    sharedUsersList.value = sharedUsersList.value
                        .where((selectedUser) =>
                            selectedUser.id != users[index].id)
                        .toSet();
                  } else {
                    sharedUsersList.value = {
                      ...sharedUsersList.value,
                      users[index]
                    };
                  }
                },
              );
            }),
            itemCount: users.length,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'share_invite',
          style: TextStyle(color: Colors.black),
        ).tr(),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: GoRouter.of(context).pop,
        ),
        actions: [
          TextButton(
              onPressed:
                  sharedUsersList.value.isEmpty ? null : _createSharedAlbum,
              child: const Text(
                "share_create_album",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ).tr())
        ],
      ),
      body: suggestedShareUsers.when(
        data: (users) {
          return _buildUserList(users);
        },
        error: (e, _) => Text("Error loading suggested users $e"),
        loading: () => const Center(
          child: ImmichLoadingIndicator(),
        ),
      ),
    );
  }
}
