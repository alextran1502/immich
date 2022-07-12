import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/home/providers/home_page_state.provider.dart';
import 'package:immich_mobile/modules/home/ui/daily_title_text.dart';
import 'package:immich_mobile/modules/home/ui/draggable_scrollbar.dart';
import 'package:immich_mobile/modules/home/ui/image_grid.dart';
import 'package:immich_mobile/modules/home/ui/monthly_title_text.dart';
import 'package:immich_mobile/modules/photos/ui/control_bottom_app_bar.dart';
import 'package:immich_mobile/modules/photos/ui/disable_multi_select_button.dart';
import 'package:immich_mobile/modules/photos/ui/immich_sliver_appbar.dart';
import 'package:immich_mobile/modules/photos/ui/profile_drawer.dart';
import 'package:immich_mobile/shared/providers/asset.provider.dart';
import 'package:immich_mobile/shared/providers/server_info.provider.dart';
import 'package:immich_mobile/shared/providers/websocket.provider.dart';

class PhotosPage extends HookConsumerWidget {
  const PhotosPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ScrollController scrollController = useScrollController();
    var assetGroupByDateTime = ref.watch(assetGroupByDateTimeProvider);
    List<Widget> imageGridGroup = [];
    var isMultiSelectEnable =
        ref.watch(homePageStateProvider).isMultiSelectEnable;
    var homePageState = ref.watch(homePageStateProvider);

    useEffect(() {
      ref.read(websocketProvider.notifier).connect();
      ref.read(assetProvider.notifier).getAllAsset();
      ref.watch(serverInfoProvider.notifier).getServerVersion();
      return null;
    }, []);

    void reloadAllAsset() {
      ref.read(assetProvider.notifier).getAllAsset();
    }

    _buildSelectedItemCountIndicator() {
      return DisableMultiSelectButton(
        onPressed: ref.watch(homePageStateProvider.notifier).disableMultiSelect,
        selectedItemCount: homePageState.selectedItems.length,
      );
    }

    Widget _buildBody() {
      if (assetGroupByDateTime.isNotEmpty) {
        int? lastMonth;

        assetGroupByDateTime.forEach((dateGroup, immichAssetList) {
          DateTime parseDateGroup = DateTime.parse(dateGroup);
          int currentMonth = parseDateGroup.month;

          if (lastMonth != null) {
            if (currentMonth - lastMonth! != 0) {
              imageGridGroup.add(
                MonthlyTitleText(
                  isoDate: dateGroup,
                ),
              );
            }
          }

          imageGridGroup.add(
            DailyTitleText(
              isoDate: dateGroup,
              assetGroup: immichAssetList,
            ),
          );

          imageGridGroup.add(
            ImageGrid(assetGroup: immichAssetList),
          );

          lastMonth = currentMonth;
        });
      }

      _buildSliverAppBar() {
        return isMultiSelectEnable
            ? const SliverToBoxAdapter(
                child: SizedBox(height: 70),
              )
            : ImmichSliverAppBar(
                onPopBack: reloadAllAsset,
              );
      }

      return SafeArea(
        bottom: !isMultiSelectEnable,
        top: !isMultiSelectEnable,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: DraggableScrollbar.semicircle(
                backgroundColor: Theme.of(context).primaryColor,
                controller: scrollController,
                heightScrollThumb: 48.0,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    ...imageGridGroup,
                  ],
                ),
              ),
            ),
            if (isMultiSelectEnable) ...[
              _buildSelectedItemCountIndicator(),
              const ControlBottomAppBar(),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      drawer: const ProfileDrawer(),
      body: _buildBody(),
    );
  }
}
