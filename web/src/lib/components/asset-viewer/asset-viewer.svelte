<script lang="ts">
	import { createEventDispatcher, onDestroy, onMount } from 'svelte';
	import { fly } from 'svelte/transition';
	import AsserViewerNavBar from './asser-viewer-nav-bar.svelte';
	import ChevronRight from 'svelte-material-icons/ChevronRight.svelte';
	import ChevronLeft from 'svelte-material-icons/ChevronLeft.svelte';
	import PhotoViewer from './photo-viewer.svelte';
	import DetailPanel from './detail-panel.svelte';
	import { session } from '$app/stores';
	import { downloadAssets } from '$lib/stores/download';
	import VideoViewer from './video-viewer.svelte';
	import { api, AssetResponseDto, AssetTypeEnum } from '@api';
	import { browser } from '$app/env';

	const dispatch = createEventDispatcher();

	export let asset: AssetResponseDto;

	let halfLeftHover = false;
	let halfRightHover = false;
	let isShowDetail = false;

	onMount(() => {
		if (browser) {
			document.addEventListener('keydown', (keyInfo) => handleKeyboardPress(keyInfo.key));
		}
	});

	const handleKeyboardPress = (key: string) => {
		switch (key) {
			case 'Escape':
				closeViewer();
				return;
			case 'i':
				isShowDetail = !isShowDetail;
				return;
			case 'ArrowLeft':
				navigateAssetBackward();
				return;
			case 'ArrowRight':
				navigateAssetForward();
				return;
		}
	};

	const closeViewer = () => {
		dispatch('close');
	};

	const navigateAssetForward = (e?: Event) => {
		e?.stopPropagation();
		dispatch('navigate-forward');
	};

	const navigateAssetBackward = (e?: Event) => {
		e?.stopPropagation();
		dispatch('navigate-backward');
	};

	const showDetailInfoHandler = () => {
		isShowDetail = !isShowDetail;
	};

	const downloadFile = async () => {
		try {
			const imageName = asset.exifInfo?.imageName ? asset.exifInfo?.imageName : asset.id;
			const imageExtension = asset.originalPath.split('.')[1];
			const imageFileName = imageName + '.' + imageExtension;

			// If assets is already download -> return;
			if ($downloadAssets[imageFileName]) {
				return;
			}

			$downloadAssets[imageFileName] = 0;

			const { data, status } = await api.assetApi.downloadFile(
				asset.deviceAssetId,
				asset.deviceId,
				false,
				false,
				{
					responseType: 'blob',
					onDownloadProgress: (progressEvent) => {
						if (progressEvent.lengthComputable) {
							const total = progressEvent.total;
							const current = progressEvent.loaded;
							let percentCompleted = Math.floor((current / total) * 100);

							$downloadAssets[imageFileName] = percentCompleted;
						}
					}
				}
			);

			if (!(data instanceof Blob)) {
				return;
			}

			if (status === 200) {
				const fileUrl = URL.createObjectURL(data);
				const anchor = document.createElement('a');
				anchor.href = fileUrl;
				anchor.download = imageFileName;

				document.body.appendChild(anchor);
				anchor.click();
				document.body.removeChild(anchor);

				URL.revokeObjectURL(fileUrl);

				// Remove item from download list
				setTimeout(() => {
					const copy = $downloadAssets;
					delete copy[imageFileName];
					$downloadAssets = copy;
				}, 2000);
			}
		} catch (e) {
			console.log('Error downloading file ', e);
		}
	};
</script>

<section
	id="immich-asset-viewer"
	class="fixed h-screen w-screen top-0 overflow-y-hidden bg-black z-[999] grid grid-rows-[64px_1fr] grid-cols-4  "
>
	<div class="col-start-1 col-span-4 row-start-1 row-span-1 z-[1000] transition-transform">
		<AsserViewerNavBar
			on:goBack={closeViewer}
			on:showDetail={showDetailInfoHandler}
			on:download={downloadFile}
		/>
	</div>

	<div
		class={`row-start-2 row-span-end col-start-1 col-span-2 flex place-items-center hover:cursor-pointer w-3/4 ${
			asset.type == AssetTypeEnum.Video ? '' : 'z-[999]'
		}`}
		on:mouseenter={() => {
			halfLeftHover = true;
			halfRightHover = false;
		}}
		on:mouseleave={() => {
			halfLeftHover = false;
		}}
		on:click={navigateAssetBackward}
	>
		<button
			class="rounded-full p-3 hover:bg-gray-500 hover:text-gray-700 z-[1000]  text-gray-500 mx-4"
			class:navigation-button-hover={halfLeftHover}
			on:click={navigateAssetBackward}
		>
			<ChevronLeft size="36" />
		</button>
	</div>

	<div class="row-start-1 row-span-full col-start-1 col-span-4">
		{#key asset.id}
			{#if asset.type == AssetTypeEnum.Image}
				<PhotoViewer assetId={asset.id} deviceId={asset.deviceId} on:close={closeViewer} />
			{:else}
				<VideoViewer assetId={asset.id} on:close={closeViewer} />
			{/if}
		{/key}
	</div>

	<div
		class={`row-start-2 row-span-full col-start-3 col-span-2 flex justify-end place-items-center hover:cursor-pointer w-3/4 justify-self-end ${
			asset.type == AssetTypeEnum.Video ? '' : 'z-[500]'
		}`}
		on:click={navigateAssetForward}
		on:mouseenter={() => {
			halfLeftHover = false;
			halfRightHover = true;
		}}
		on:mouseleave={() => {
			halfRightHover = false;
		}}
	>
		<button
			class="rounded-full p-3 hover:bg-gray-500 hover:text-gray-700 text-gray-500 mx-4 z-[1000]"
			class:navigation-button-hover={halfRightHover}
			on:click={navigateAssetForward}
		>
			<ChevronRight size="36" />
		</button>
	</div>

	{#if isShowDetail}
		<div
			transition:fly={{ duration: 150 }}
			id="detail-panel"
			class="bg-immich-bg w-[360px] row-span-full transition-all "
			translate="yes"
		>
			<DetailPanel {asset} on:close={() => (isShowDetail = false)} />
		</div>
	{/if}
</section>

<style>
	.navigation-button-hover {
		background-color: rgb(107 114 128 / var(--tw-bg-opacity));
		color: rgb(55 65 81 / var(--tw-text-opacity));
		transition: all 150ms;
	}
</style>
