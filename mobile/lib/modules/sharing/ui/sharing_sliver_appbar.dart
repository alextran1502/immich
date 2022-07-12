import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:immich_mobile/routing/router.dart';

class SharingSliverAppBar extends StatelessWidget {
  const SharingSliverAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      centerTitle: true,
      floating: false,
      pinned: true,
      snap: false,
      automaticallyImplyLeading: false,
      // leading: Container(),
      // elevation: 0,
      title: Text(
        'IMMICH',
        style: TextStyle(
          fontFamily: 'SnowburstOne',
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Theme.of(context).primaryColor,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: TextButton.icon(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          Theme.of(context).primaryColor.withAlpha(20)),
                      // foregroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                    onPressed: () {
                      GoRouter.of(context)
                          .pushNamed('${ImmichRoute.createSharedAlbum}');
                    },
                    icon: const Icon(
                      Icons.photo_album_outlined,
                      size: 20,
                    ),
                    label: const Text(
                      "sharing_silver_appbar_create_shared_album",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ).tr(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: TextButton.icon(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          Theme.of(context).primaryColor.withAlpha(20)),
                      // foregroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                    onPressed: null,
                    icon: const Icon(
                      Icons.swap_horizontal_circle_outlined,
                      size: 20,
                    ),
                    label: const Text(
                      "sharing_silver_appbar_share_partner",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ).tr(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
