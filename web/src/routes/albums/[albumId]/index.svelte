<script lang="ts">
	import AlbumViewer from '$lib/components/album-page/album-viewer.svelte';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { AlbumResponseDto, api } from '@api';
	import { afterNavigate } from '$app/navigation';

	let album: AlbumResponseDto;
	let backUrl: string = '/albums';

	onMount(async () => {
		const albumId = $page.params['albumId'];
		const { data } = await api.albumApi.getAlbumInfo(albumId);
		album = data;
	});

	afterNavigate(({ from }) => {
		if (from?.pathname === '/sharing') {
			backUrl = '/sharing';
		}
	});
</script>

<svelte:head>
	<title>{album?.albumName} - Immich</title>
</svelte:head>

<div class="relative immich-scrollbar">
	{#if album}
		<AlbumViewer {album} {backUrl} />
	{/if}
</div>
