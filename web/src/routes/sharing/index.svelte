<script lang="ts">
	import NavigationBar from '$lib/components/shared-components/navigation-bar.svelte';
	import SideBar from '$lib/components/shared-components/side-bar/side-bar.svelte';
	import PlusBoxOutline from 'svelte-material-icons/PlusBoxOutline.svelte';
	import SharedAlbumListTile from '$lib/components/sharing-page/shared-album-list-tile.svelte';
	import { session } from '$app/stores';
	import { checkUserAuthStatus, gotoLogin } from '$lib/user_auth';
	import { AlbumResponseDto, api, UserResponseDto } from '@api';
	import { goto } from '$app/navigation';

	let sharedAlbums: AlbumResponseDto[] = [];
	let user: UserResponseDto;

	checkUserAuthStatus()
		.then((authUser) => {
			user = authUser;
		})
		.catch(() => {
			gotoLogin();
		});

	api.albumApi.getAllAlbums(true).then((resp) => {
		sharedAlbums = resp.data;
	});

	const createSharedAlbum = async () => {
		try {
			const { data: newAlbum } = await api.albumApi.createAlbum({
				albumName: 'Untitled'
			});

			goto('/albums/' + newAlbum.id);
		} catch (e) {
			console.log('Error [createAlbum] ', e);
		}
	};

	const deleteAlbum = async (album: AlbumResponseDto) => {
		try {
			await api.albumApi.deleteAlbum(album.id);
			return true;
		} catch (e) {
			console.log('Error [deleteAlbum] ', e);
			return false;
		}
	};
</script>

<svelte:head>
	<title>Albums - Immich</title>
</svelte:head>

<section>
	{#if user}
		<NavigationBar {user} on:uploadClicked={() => {}} />
	{/if}
</section>

<section class="grid grid-cols-[250px_auto] relative pt-[72px] h-screen bg-immich-bg">
	<SideBar />

	<section class="overflow-y-auto relative">
		<section id="album-content" class="relative pt-8 pl-4 mb-12 bg-immich-bg">
			<!-- Main Section -->
			<div class="px-4 flex justify-between place-items-center">
				<div>
					<p class="font-medium">Sharing</p>
				</div>

				<div>
					<button
						on:click={createSharedAlbum}
						class="flex place-items-center gap-1 text-sm hover:bg-immich-primary/5 p-2 rounded-lg font-medium hover:text-gray-700"
					>
						<span>
							<PlusBoxOutline size="18" />
						</span>
						<p>Create shared album</p>
					</button>
				</div>
			</div>

			<div class="my-4">
				<hr />
			</div>

			<!-- Share Album List -->
			<div class="w-full flex flex-col place-items-center">
				{#if user}
					{#each sharedAlbums as album}
						<a sveltekit:prefetch href={`albums/${album.id}`}>
							<SharedAlbumListTile {album} {user} />
						</a>
					{/each}
				{/if}
			</div>
		</section>
	</section>
</section>
