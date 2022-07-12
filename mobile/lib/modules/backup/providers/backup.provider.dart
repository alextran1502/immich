import 'package:cancellation_token_http/http.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:immich_mobile/modules/backup/models/available_album.model.dart';
import 'package:immich_mobile/modules/backup/models/backup_state.model.dart';
import 'package:immich_mobile/modules/backup/models/current_upload_asset.model.dart';
import 'package:immich_mobile/modules/backup/models/error_upload_asset.model.dart';
import 'package:immich_mobile/modules/backup/models/hive_backup_albums.model.dart';
import 'package:immich_mobile/modules/backup/providers/error_backup_list.provider.dart';
import 'package:immich_mobile/modules/backup/services/backup.service.dart';
import 'package:immich_mobile/modules/login/models/authentication_state.model.dart';
import 'package:immich_mobile/modules/login/providers/authentication.provider.dart';
import 'package:immich_mobile/shared/models/server_info.model.dart';
import 'package:immich_mobile/shared/services/server_info.service.dart';
import 'package:photo_manager/photo_manager.dart';

class BackupNotifier extends StateNotifier<BackUpState> {
  BackupNotifier(
    this._backupService,
    this._serverInfoService,
    this._authState,
    this.ref,
  ) : super(
          BackUpState(
            backupProgress: BackUpProgressEnum.idle,
            allAssetsInDatabase: const [],
            progressInPercentage: 0,
            cancelToken: CancellationToken(),
            serverInfo: ServerInfo(
              diskAvailable: "0",
              diskAvailableRaw: 0,
              diskSize: "0",
              diskSizeRaw: 0,
              diskUsagePercentage: 0.0,
              diskUse: "0",
              diskUseRaw: 0,
            ),
            availableAlbums: const [],
            selectedBackupAlbums: const {},
            excludedBackupAlbums: const {},
            allUniqueAssets: const {},
            selectedAlbumsBackupAssetsIds: const {},
            currentUploadAsset: CurrentUploadAsset(
              id: '...',
              createdAt: DateTime.parse('2020-10-04'),
              fileName: '...',
              fileType: '...',
            ),
          ),
        ) {
    getBackupInfo();
  }

  final BackupService _backupService;
  final ServerInfoService _serverInfoService;
  final AuthenticationState _authState;
  final Ref ref;

  ///
  /// UI INTERACTION
  ///
  /// Album selection
  /// Due to the overlapping assets across multiple albums on the device
  /// We have method to include and exclude albums
  /// The total unique assets will be used for backing mechanism
  ///
  void addAlbumForBackup(AssetPathEntity album) {
    if (state.excludedBackupAlbums.contains(album)) {
      removeExcludedAlbumForBackup(album);
    }

    state = state
        .copyWith(selectedBackupAlbums: {...state.selectedBackupAlbums, album});
    _updateBackupAssetCount();
  }

  void addExcludedAlbumForBackup(AssetPathEntity album) {
    if (state.selectedBackupAlbums.contains(album)) {
      removeAlbumForBackup(album);
    }
    state = state
        .copyWith(excludedBackupAlbums: {...state.excludedBackupAlbums, album});
    _updateBackupAssetCount();
  }

  void removeAlbumForBackup(AssetPathEntity album) {
    Set<AssetPathEntity> currentSelectedAlbums = state.selectedBackupAlbums;

    currentSelectedAlbums.removeWhere((a) => a == album);

    state = state.copyWith(selectedBackupAlbums: currentSelectedAlbums);
    _updateBackupAssetCount();
  }

  void removeExcludedAlbumForBackup(AssetPathEntity album) {
    Set<AssetPathEntity> currentExcludedAlbums = state.excludedBackupAlbums;

    currentExcludedAlbums.removeWhere((a) => a == album);

    state = state.copyWith(excludedBackupAlbums: currentExcludedAlbums);
    _updateBackupAssetCount();
  }

  ///
  /// Get all album on the device
  /// Get all selected and excluded album from the user's persistent storage
  /// If this is the first time performing backup - set the default selected album to be
  /// the one that has all assets (Recent on Android, Recents on iOS)
  ///
  Future<void> _getBackupAlbumsInfo() async {
    // Get all albums on the device
    List<AvailableAlbum> availableAlbums = [];
    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        hasAll: true, type: RequestType.common);

    for (AssetPathEntity album in albums) {
      AvailableAlbum availableAlbum = AvailableAlbum(albumEntity: album);

      var assetList =
          await album.getAssetListRange(start: 0, end: album.assetCount);

      if (assetList.isNotEmpty) {
        var thumbnailAsset = assetList.first;
        var thumbnailData = await thumbnailAsset
            .thumbnailDataWithSize(const ThumbnailSize(512, 512));
        availableAlbum = availableAlbum.copyWith(thumbnailData: thumbnailData);
      }

      availableAlbums.add(availableAlbum);
    }

    state = state.copyWith(availableAlbums: availableAlbums);

    // Put persistent storage info into local state of the app
    // Get local storage on selected backup album
    Box<HiveBackupAlbums> backupAlbumInfoBox =
        Hive.box<HiveBackupAlbums>(hiveBackupInfoBox);
    HiveBackupAlbums? backupAlbumInfo = backupAlbumInfoBox.get(
      backupInfoKey,
      defaultValue: HiveBackupAlbums(
        selectedAlbumIds: [],
        excludedAlbumsIds: [],
      ),
    );

    if (backupAlbumInfo == null) {
      debugPrint("[ERROR] getting Hive backup album infomation");
      return;
    }

    // First time backup - set isAll album is the default one for backup.
    if (backupAlbumInfo.selectedAlbumIds.isEmpty) {
      debugPrint("First time backup setup recent album as default");

      // Get album that contains all assets
      var list = await PhotoManager.getAssetPathList(
          hasAll: true, onlyAll: true, type: RequestType.common);
      AssetPathEntity albumHasAllAssets = list.first;

      backupAlbumInfoBox.put(
        backupInfoKey,
        HiveBackupAlbums(
          selectedAlbumIds: [albumHasAllAssets.id],
          excludedAlbumsIds: [],
        ),
      );

      backupAlbumInfo = backupAlbumInfoBox.get(backupInfoKey);
    }

    // Generate AssetPathEntity from id to add to local state
    try {
      for (var selectedAlbumId in backupAlbumInfo!.selectedAlbumIds) {
        var albumAsset = await AssetPathEntity.fromId(selectedAlbumId);
        state = state.copyWith(
            selectedBackupAlbums: {...state.selectedBackupAlbums, albumAsset});
      }

      for (var excludedAlbumId in backupAlbumInfo.excludedAlbumsIds) {
        var albumAsset = await AssetPathEntity.fromId(excludedAlbumId);
        state = state.copyWith(
            excludedBackupAlbums: {...state.excludedBackupAlbums, albumAsset});
      }
    } catch (e) {
      debugPrint("[ERROR] Failed to generate album from id $e");
    }
  }

  ///
  /// From all the selected and albums assets
  /// Find the assets that are not overlapping between the two sets
  /// Those assets are unique and are used as the total assets
  ///
  Future<void> _updateBackupAssetCount() async {
    Set<AssetEntity> assetsFromSelectedAlbums = {};
    Set<AssetEntity> assetsFromExcludedAlbums = {};

    for (var album in state.selectedBackupAlbums) {
      var assets =
          await album.getAssetListRange(start: 0, end: album.assetCount);
      assetsFromSelectedAlbums.addAll(assets);
    }

    for (var album in state.excludedBackupAlbums) {
      var assets =
          await album.getAssetListRange(start: 0, end: album.assetCount);
      assetsFromExcludedAlbums.addAll(assets);
    }

    Set<AssetEntity> allUniqueAssets =
        assetsFromSelectedAlbums.difference(assetsFromExcludedAlbums);
    List<String> allAssetsInDatabase =
        await _backupService.getDeviceBackupAsset();

    // Find asset that were backup from selected albums
    Set<String> selectedAlbumsBackupAssets =
        Set.from(allUniqueAssets.map((e) => e.id));
    selectedAlbumsBackupAssets
        .removeWhere((assetId) => !allAssetsInDatabase.contains(assetId));

    if (allUniqueAssets.isEmpty) {
      debugPrint("No Asset On Device");
      state = state.copyWith(
        backupProgress: BackUpProgressEnum.idle,
        allAssetsInDatabase: allAssetsInDatabase,
        allUniqueAssets: {},
        selectedAlbumsBackupAssetsIds: selectedAlbumsBackupAssets,
      );
      return;
    } else {
      state = state.copyWith(
        allAssetsInDatabase: allAssetsInDatabase,
        allUniqueAssets: allUniqueAssets,
        selectedAlbumsBackupAssetsIds: selectedAlbumsBackupAssets,
      );
    }

    // Save to persistent storage
    _updatePersistentAlbumsSelection();

    return;
  }

  ///
  /// Get all necessary information for calculating the available albums,
  /// which albums are selected or excluded
  /// and then update the UI according to those information
  ///
  Future<void> getBackupInfo() async {
    await Future.wait([
      _getBackupAlbumsInfo(),
      _updateServerInfo(),
    ]);

    await _updateBackupAssetCount();
  }

  ///
  /// Save user selection of selected albums and excluded albums to
  /// Hive database
  ///
  void _updatePersistentAlbumsSelection() {
    Box<HiveBackupAlbums> backupAlbumInfoBox =
        Hive.box<HiveBackupAlbums>(hiveBackupInfoBox);
    backupAlbumInfoBox.put(
      backupInfoKey,
      HiveBackupAlbums(
        selectedAlbumIds: state.selectedBackupAlbums.map((e) => e.id).toList(),
        excludedAlbumsIds: state.excludedBackupAlbums.map((e) => e.id).toList(),
      ),
    );
  }

  ///
  /// Invoke backup process
  ///
  void startBackupProcess() async {
    var localState =
        state.copyWith(backupProgress: BackUpProgressEnum.inProgress);

    await getBackupInfo();

    var authResult = await PhotoManager.requestPermissionExtend();
    if (authResult.isAuth) {
      await PhotoManager.clearFileCache();

      if (localState.allUniqueAssets.isEmpty) {
        debugPrint("No Asset On Device - Abort Backup Process");
        localState = state.copyWith(backupProgress: BackUpProgressEnum.idle);
        return;
      }

      Set<AssetEntity> assetsWillBeBackup = Set.from(state.allUniqueAssets);

      // Remove item that has already been backed up
      for (var assetId in localState.allAssetsInDatabase) {
        assetsWillBeBackup.removeWhere((e) => e.id == assetId);
      }

      if (assetsWillBeBackup.isEmpty) {
        localState =
            localState.copyWith(backupProgress: BackUpProgressEnum.idle);
      }

      // Perform Backup
      state = localState.copyWith(cancelToken: CancellationToken());
      _backupService.backupAsset(
        assetsWillBeBackup,
        state.cancelToken,
        _onAssetUploaded,
        _onUploadProgress,
        _onSetCurrentBackupAsset,
        _onBackupError,
      );
    } else {
      PhotoManager.openSetting();
    }
  }

  void _onBackupError(ErrorUploadAsset errorAssetInfo) {
    ref.watch(errorBackupListProvider.notifier).add(errorAssetInfo);
  }

  void _onSetCurrentBackupAsset(CurrentUploadAsset currentUploadAsset) {
    state = state.copyWith(currentUploadAsset: currentUploadAsset);
  }

  void cancelBackup() {
    state.cancelToken.cancel();
    state = state.copyWith(
        backupProgress: BackUpProgressEnum.idle, progressInPercentage: 0.0);
  }

  void _onAssetUploaded(String deviceAssetId, String deviceId) {
    state = state.copyWith(selectedAlbumsBackupAssetsIds: {
      ...state.selectedAlbumsBackupAssetsIds,
      deviceAssetId
    }, allAssetsInDatabase: [
      ...state.allAssetsInDatabase,
      deviceAssetId
    ]);

    if (state.allUniqueAssets.length -
            state.selectedAlbumsBackupAssetsIds.length ==
        0) {
      state = state.copyWith(
          backupProgress: BackUpProgressEnum.done, progressInPercentage: 0.0);
    }

    _updateServerInfo();
  }

  void _onUploadProgress(int sent, int total) {
    state = state.copyWith(
        progressInPercentage: (sent.toDouble() / total.toDouble() * 100));
  }

  Future<void> _updateServerInfo() async {
    var serverInfo = await _serverInfoService.getServerInfo();

    // Update server info
    state = state.copyWith(
      serverInfo: ServerInfo(
        diskSize: serverInfo.diskSize,
        diskUse: serverInfo.diskUse,
        diskAvailable: serverInfo.diskAvailable,
        diskSizeRaw: serverInfo.diskSizeRaw,
        diskUseRaw: serverInfo.diskUseRaw,
        diskAvailableRaw: serverInfo.diskAvailableRaw,
        diskUsagePercentage: serverInfo.diskUsagePercentage,
      ),
    );
  }

  void resumeBackup() {
    // Check if user is login
    var accessKey = Hive.box(userInfoBox).get(accessTokenKey);

    // User has been logged out return
    if (accessKey == null || !_authState.isAuthenticated) {
      debugPrint("[resumeBackup] not authenticated - abort");
      return;
    }

    // Check if this device is enable backup by the user
    if ((_authState.deviceInfo.deviceId == _authState.deviceId) &&
        _authState.deviceInfo.isAutoBackup) {
      // check if backup is alreayd in process - then return
      if (state.backupProgress == BackUpProgressEnum.inProgress) {
        debugPrint("[resumeBackup] Backup is already in progress - abort");
        return;
      }

      // Run backup
      debugPrint("[resumeBackup] Start back up");
      startBackupProcess();
    }

    return;
  }
}

final backupProvider =
    StateNotifierProvider<BackupNotifier, BackUpState>((ref) {
  return BackupNotifier(
    ref.watch(backupServiceProvider),
    ref.watch(serverInfoServiceProvider),
    ref.watch(authenticationProvider),
    ref,
  );
});
