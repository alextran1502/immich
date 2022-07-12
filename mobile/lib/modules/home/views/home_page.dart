import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/home/providers/home_page_state.provider.dart';
import 'package:immich_mobile/modules/photos/views/photos_page.dart';
import 'package:immich_mobile/modules/search/views/search_page.dart';
import 'package:immich_mobile/modules/sharing/views/sharing_page.dart';

final indexProvider = StateProvider((ref) => 0);

class HomePage extends HookConsumerWidget {
  final int initTabIndex;
  const HomePage({
    super.key,
    this.initTabIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isMultiSelectEnable =
        ref.watch(homePageStateProvider).isMultiSelectEnable;

    useEffect(() {
      ref.watch(indexProvider.state).state = initTabIndex;
      return null;
    }, []);

    return Scaffold(
      body: IndexedStack(
        index: ref.watch(indexProvider.state).state,
        children: const [
          PhotosPage(),
          SearchPage(),
          SharingPage(),
        ],
      ),
      bottomNavigationBar: isMultiSelectEnable
          ? null
          : BottomNavigationBar(
              currentIndex: ref.watch(indexProvider.state).state,
              onTap: (index) => ref.read(indexProvider.state).state = index,
              items: [
                BottomNavigationBarItem(
                  label: 'tab_controller_nav_photos'.tr(),
                  icon: const Icon(Icons.photo),
                ),
                BottomNavigationBarItem(
                  label: 'tab_controller_nav_search'.tr(),
                  icon: const Icon(Icons.search),
                ),
                BottomNavigationBarItem(
                  label: 'tab_controller_nav_sharing'.tr(),
                  icon: const Icon(Icons.group_outlined),
                ),
              ],
            ),
    );
  }
}
