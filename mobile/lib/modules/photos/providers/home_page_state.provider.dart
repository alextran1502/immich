import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/home/models/home_page_state.model.dart';
import 'package:immich_mobile/shared/models/immich_asset.model.dart';

class HomePageStateNotifier extends StateNotifier<HomePageState> {
  HomePageStateNotifier()
      : super(
          HomePageState(
            isMultiSelectEnable: false,
            selectedItems: {},
            selectedDateGroup: {},
          ),
        );

  void addSelectedDateGroup(String dateGroupTitle) {
    state = state.copyWith(
        selectedDateGroup: {...state.selectedDateGroup, dateGroupTitle});
  }

  void removeSelectedDateGroup(String dateGroupTitle) {
    var currentDateGroup = state.selectedDateGroup;

    currentDateGroup.removeWhere((e) => e == dateGroupTitle);

    state = state.copyWith(selectedDateGroup: currentDateGroup);
  }

  void enableMultiSelect(Set<ImmichAsset> selectedItems) {
    state =
        state.copyWith(isMultiSelectEnable: true, selectedItems: selectedItems);
  }

  void disableMultiSelect() {
    state = state.copyWith(
        isMultiSelectEnable: false, selectedItems: {}, selectedDateGroup: {});
  }

  void addSingleSelectedItem(ImmichAsset asset) {
    state = state.copyWith(selectedItems: {...state.selectedItems, asset});
  }

  void addMultipleSelectedItems(List<ImmichAsset> assets) {
    state = state.copyWith(selectedItems: {...state.selectedItems, ...assets});
  }

  void removeSingleSelectedItem(ImmichAsset asset) {
    Set<ImmichAsset> currentList = state.selectedItems;

    currentList.removeWhere((e) => e.id == asset.id);

    state = state.copyWith(selectedItems: currentList);
  }

  void removeMultipleSelectedItem(List<ImmichAsset> assets) {
    Set<ImmichAsset> currentList = state.selectedItems;

    for (ImmichAsset asset in assets) {
      currentList.removeWhere((e) => e.id == asset.id);
    }

    state = state.copyWith(selectedItems: currentList);
  }
}

final homePageStateProvider =
    StateNotifierProvider<HomePageStateNotifier, HomePageState>(
        ((ref) => HomePageStateNotifier()));
