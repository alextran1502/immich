import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:immich_mobile/shared/models/immich_asset.model.dart';

class HomePageState {
  final bool isMultiSelectEnable;
  final Set<ImmichAsset> selectedItems;
  final Set<String> selectedDateGroup;
  HomePageState({
    required this.isMultiSelectEnable,
    required this.selectedItems,
    required this.selectedDateGroup,
  });

  HomePageState copyWith({
    bool? isMultiSelectEnable,
    Set<ImmichAsset>? selectedItems,
    Set<String>? selectedDateGroup,
  }) {
    return HomePageState(
      isMultiSelectEnable: isMultiSelectEnable ?? this.isMultiSelectEnable,
      selectedItems: selectedItems ?? this.selectedItems,
      selectedDateGroup: selectedDateGroup ?? this.selectedDateGroup,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isMultiSelectEnable': isMultiSelectEnable,
      'selectedItems': selectedItems.map((x) => x.toMap()).toList(),
      'selectedDateGroup': selectedDateGroup.toList(),
    };
  }

  factory HomePageState.fromMap(Map<String, dynamic> map) {
    return HomePageState(
      isMultiSelectEnable: map['isMultiSelectEnable'] ?? false,
      selectedItems: Set<ImmichAsset>.from(
          map['selectedItems']?.map((x) => ImmichAsset.fromMap(x))),
      selectedDateGroup: Set<String>.from(map['selectedDateGroup']),
    );
  }

  String toJson() => json.encode(toMap());

  factory HomePageState.fromJson(String source) =>
      HomePageState.fromMap(json.decode(source));

  @override
  String toString() =>
      'HomePageState(isMultiSelectEnable: $isMultiSelectEnable, selectedItems: $selectedItems, selectedDateGroup: $selectedDateGroup)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final setEquals = const DeepCollectionEquality().equals;

    return other is HomePageState &&
        other.isMultiSelectEnable == isMultiSelectEnable &&
        setEquals(other.selectedItems, selectedItems) &&
        setEquals(other.selectedDateGroup, selectedDateGroup);
  }

  @override
  int get hashCode =>
      isMultiSelectEnable.hashCode ^
      selectedItems.hashCode ^
      selectedDateGroup.hashCode;
}
