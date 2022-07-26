<script lang="ts">
	import { session } from '$app/stores';
	import { fade } from 'svelte/transition';

	import { createEventDispatcher, onMount } from 'svelte';
	import LoadingSpinner from '../shared-components/loading-spinner.svelte';
	import { api, AssetResponseDto } from '@api';

	export let assetId: string;

	let asset: AssetResponseDto;

	const dispatch = createEventDispatcher();

	let videoPlayerNode: HTMLVideoElement;
	let isVideoLoading = true;

	onMount(async () => {
		const { data: assetInfo } = await api.assetApi.getAssetById(assetId);

		asset = assetInfo;

		await loadVideoData();
	});

	const loadVideoData = async () => {
		isVideoLoading = true;

		try {
			const { data } = await api.assetApi.serveFile(
				asset.deviceAssetId,
				asset.deviceId,
				false,
				true,
				{
					responseType: 'blob'
				}
			);

			if (!(data instanceof Blob)) {
				return;
			}

			const videoData = URL.createObjectURL(data);
			videoPlayerNode.src = videoData;

			videoPlayerNode.load();

			videoPlayerNode.oncanplay = () => {
				videoPlayerNode.muted = true;
				videoPlayerNode.play();
				videoPlayerNode.muted = false;

				isVideoLoading = false;
			};

			return videoData;
		} catch (e) {}
	};
</script>

<div
	transition:fade={{ duration: 150 }}
	class="flex place-items-center place-content-center h-full select-none"
>
	{#if asset}
		<video controls class="h-full object-contain" bind:this={videoPlayerNode}>
			<track kind="captions" />
		</video>

		{#if isVideoLoading}
			<div class="absolute flex place-items-center place-content-center">
				<LoadingSpinner />
			</div>
		{/if}
	{/if}
</div>
