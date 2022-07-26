<script lang="ts">
	import AlbumCard from '$lib/components/album-page/album-card.svelte';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import PlusBoxOutline from 'svelte-material-icons/PlusBoxOutline.svelte';
	import NavigationBar from '$lib/components/shared-components/navigation-bar.svelte';
	import { ImmichUser } from '$lib/models/immich-user';
	import SideBar from '$lib/components/shared-components/side-bar/side-bar.svelte';
	import { AlbumResponseDto, api } from '@api';
	import { checkUserAuthStatus, gotoLogin } from '$lib/user_auth';
	import { session } from '$app/stores';
	import ContextMenu from '$lib/components/shared-components/context-menu/context-menu.svelte';
	import MenuOption from '$lib/components/shared-components/context-menu/menu-option.svelte';
	import DeleteOutline from 'svelte-material-icons/DeleteOutline.svelte';

	let albums: AlbumResponseDto[] = [];

	checkUserAuthStatus().catch(() => gotoLogin());

	let isShowContextMenu = false;
	let contextMenuPosition = { x: 0, y: 0 };
	let targetAlbum: AlbumResponseDto;

	onMount(async () => {
		const { data } = await api.albumApi.getAllAlbums();
		albums = data;
		// Delete album that has no photos and is named 'Untitled'
		for (const album of albums) {
			if (album.albumName === 'Untitled' && album.assets.length === 0) {
				const isDeleted = await autoDeleteAlbum(album);

				if (isDeleted) {
					albums = albums.filter((a) => a.id !== album.id);
				}
			}
		}
	});

	const createAlbum = async () => {
		try {
			const { data: newAlbum } = await api.albumApi.createAlbum({
				albumName: 'Untitled'
			});

			goto('/albums/' + newAlbum.id);
		} catch (e) {
			console.log('Error [createAlbum] ', e);
		}
	};

	const autoDeleteAlbum = async (album: AlbumResponseDto) => {
		try {
			await api.albumApi.deleteAlbum(album.id);
			return true;
		} catch (e) {
			console.log('Error [autoDeleteAlbum] ', e);
			return false;
		}
	};

	const userDeleteMenu = async () => {
		if (
			window.confirm(
				`Are you sure you want to delete album ${targetAlbum.albumName}? If the album is shared, other users will not be able to access it.`
			)
		) {
			try {
				await api.albumApi.deleteAlbum(targetAlbum.id);
				albums = albums.filter((a) => a.id !== targetAlbum.id);
			} catch (e) {
				console.log('Error [userDeleteMenu] ', e);
			}
		}

		isShowContextMenu = false;
	};

	const showAlbumContextMenu = (event: CustomEvent, album: AlbumResponseDto) => {
		targetAlbum = album;

		contextMenuPosition = {
			x: event.detail.x,
			y: event.detail.y
		};

		isShowContextMenu = !isShowContextMenu;
	};
</script>

<svelte:head>
	<title>Albums - Immich</title>
</svelte:head>

<section>
	{#if $session.user}
		<NavigationBar user={$session.user} on:uploadClicked={() => {}} />
	{/if}
</section>

<section class="grid grid-cols-[250px_auto] relative pt-[72px] h-screen bg-immich-bg ">
	<SideBar />

	<!-- Main Section -->

	<section class="overflow-y-auto relative immich-scrollbar">
		<section id="album-content" class="relative pt-8 pl-4 mb-12 bg-immich-bg">
			<div class="px-4 flex justify-between place-items-center">
				<div>
					<p class="font-medium">Albums</p>
				</div>

				<div>
					<button on:click={createAlbum} class="immich-text-button text-sm">
						<span>
							<PlusBoxOutline size="18" />
						</span>
						<p>Create album</p>
					</button>
				</div>
			</div>

			<div class="my-4">
				<hr />
			</div>

			<!-- Album Card -->
			<div class="flex flex-wrap gap-8">
				{#each albums as album}
					{#key album.id}
						<a sveltekit:prefetch href={`albums/${album.id}`}>
							<AlbumCard {album} on:showalbumcontextmenu={(e) => showAlbumContextMenu(e, album)} />
						</a>
					{/key}
				{/each}
			</div>
		</section>
	</section>

	<!-- Context Menu -->
	{#if isShowContextMenu}
		<ContextMenu {...contextMenuPosition} on:clickoutside={() => (isShowContextMenu = false)}>
			<MenuOption on:click={userDeleteMenu}>
				<span class="flex place-items-center place-content-center gap-2">
					<DeleteOutline size="18" />
					<p>Delete album</p>
				</span>
			</MenuOption>
		</ContextMenu>
	{/if}
</section>
