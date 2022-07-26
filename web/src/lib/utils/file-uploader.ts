/* @vite-ignore */
import * as exifr from 'exifr';
import { uploadAssetsStore } from '$lib/stores/upload';
import type { UploadAsset } from '../models/upload-asset';
import { api } from '@api';

export async function fileUploader(asset: File) {
	const assetType = asset.type.split('/')[0].toUpperCase();
	const temp = asset.name.split('.');
	const fileExtension = temp[temp.length - 1];
	const formData = new FormData();

	try {
		let exifData = null;

		if (assetType !== 'VIDEO') {
			exifData = await exifr.parse(asset);
		}

		const createdAt =
			exifData && exifData.DateTimeOriginal != null
				? new Date(exifData.DateTimeOriginal).toISOString()
				: new Date(asset.lastModified).toISOString();

		const deviceAssetId = 'web' + '-' + asset.name + '-' + asset.lastModified;

		// Create and add Unique ID of asset on the device
		formData.append('deviceAssetId', deviceAssetId);

		// Get device id - for web -> use WEB
		formData.append('deviceId', 'WEB');

		// Get asset type
		formData.append('assetType', assetType);

		// Get Asset Created Date
		formData.append('createdAt', createdAt);

		// Get Asset Modified At
		formData.append('modifiedAt', new Date(asset.lastModified).toISOString());

		// Set Asset is Favorite to false
		formData.append('isFavorite', 'false');

		// Get asset duration
		formData.append('duration', '0:00:00.000000');

		// Get asset file extension
		formData.append('fileExtension', '.' + fileExtension);

		// Get asset binary data.
		formData.append('assetData', asset);

		// Check if asset upload on server before performing upload

		const { data, status } = await api.assetApi.checkDuplicateAsset({
			deviceAssetId: String(deviceAssetId),
			deviceId: 'WEB'
		});

		if (status === 200) {
			if (data.isExist) {
				return;
			}
		}

		const request = new XMLHttpRequest();

		request.upload.onloadstart = () => {
			const newUploadAsset: UploadAsset = {
				id: deviceAssetId,
				file: asset,
				progress: 0,
				fileExtension: fileExtension
			};

			uploadAssetsStore.addNewUploadAsset(newUploadAsset);
		};

		request.upload.onload = () => {
			setTimeout(() => {
				uploadAssetsStore.removeUploadAsset(deviceAssetId);
			}, 1000);
		};

		// listen for `error` event
		request.upload.onerror = () => {
			uploadAssetsStore.removeUploadAsset(deviceAssetId);
		};

		// listen for `abort` event
		request.upload.onabort = () => {
			uploadAssetsStore.removeUploadAsset(deviceAssetId);
		};

		// listen for `progress` event
		request.upload.onprogress = (event) => {
			const percentComplete = Math.floor((event.loaded / event.total) * 100);
			uploadAssetsStore.updateProgress(deviceAssetId, percentComplete);
		};

		request.open('POST', `/api/asset/upload`);

		request.send(formData);
	} catch (e) {
		console.log('error uploading file ', e);
	}
}
