<script lang="ts">
	import { session } from '$app/stores';
	import { fade } from 'svelte/transition';

	import { createEventDispatcher, onMount } from 'svelte';
	import LoadingSpinner from '../shared-components/loading-spinner.svelte';
	import { api, AssetResponseDto } from '@api';

	export let assetId: string;
	export let deviceId: string;

	let assetInfo: AssetResponseDto;

	const dispatch = createEventDispatcher();

	onMount(async () => {
		const { data } = await api.assetApi.getAssetById(assetId);
		assetInfo = data;
	});

	const loadAssetData = async () => {
		try {
			const { data } = await api.assetApi.serveFile(
				assetInfo.deviceAssetId,
				deviceId,
				false,
				true,
				{
					responseType: 'blob'
				}
			);

			if (!(data instanceof Blob)) {
				return;
			}

			const assetData = URL.createObjectURL(data);
			return assetData;
		} catch (e) {}
	};
</script>

<div
	transition:fade={{ duration: 150 }}
	class="flex place-items-center place-content-center h-full select-none"
>
	{#if assetInfo}
		{#await loadAssetData()}
			<LoadingSpinner />
		{:then assetData}
			<img
				transition:fade={{ duration: 150 }}
				src={assetData}
				alt={assetId}
				class="object-contain h-full transition-all"
				loading="lazy"
			/>
		{/await}
	{/if}
</div>
