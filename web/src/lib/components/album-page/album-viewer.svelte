<script lang="ts">
	import { afterNavigate, beforeNavigate, goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { AlbumResponseDto, api, AssetResponseDto, ThumbnailFormat, UserResponseDto } from '@api';
	import { onMount } from 'svelte';
	import ArrowLeft from 'svelte-material-icons/ArrowLeft.svelte';
	import Plus from 'svelte-material-icons/Plus.svelte';
	import FileImagePlusOutline from 'svelte-material-icons/FileImagePlusOutline.svelte';
	import ShareVariantOutline from 'svelte-material-icons/ShareVariantOutline.svelte';
	import AssetViewer from '../asset-viewer/asset-viewer.svelte';
	import CircleAvatar from '../shared-components/circle-avatar.svelte';
	import ImmichThumbnail from '../shared-components/immich-thumbnail.svelte';
	import AssetSelection from './asset-selection.svelte';
	import _ from 'lodash-es';
	import AlbumAppBar from './album-app-bar.svelte';
	import UserSelectionModal from './user-selection-modal.svelte';
	import ShareInfoModal from './share-info-modal.svelte';
	import CircleIconButton from '../shared-components/circle-icon-button.svelte';
	import Close from 'svelte-material-icons/Close.svelte';
	import DeleteOutline from 'svelte-material-icons/DeleteOutline.svelte';

	export let album: AlbumResponseDto;
	export let backUrl = '/albums';

	let isShowAssetViewer = false;
	let isShowAssetSelection = false;
	let isShowShareUserSelection = false;
	let isEditingTitle = false;
	let isCreatingSharedAlbum = false;
	let isShowShareInfoModal = false;

	let selectedAsset: AssetResponseDto;
	let currentViewAssetIndex = 0;

	let viewWidth: number;
	let thumbnailSize: number = 300;
	let border = '';
	let currentAlbumName = '';
	let currentUser: UserResponseDto;

	$: isOwned = currentUser?.id == album.ownerId;

	let multiSelectAsset: Set<AssetResponseDto> = new Set();
	$: isMultiSelectionMode = multiSelectAsset.size > 0;

	$: {
		if (album.assets.length < 6) {
			thumbnailSize = Math.floor(viewWidth / album.assets.length - album.assets.length);
		} else {
			thumbnailSize = Math.floor(viewWidth / 6 - 6);
		}
	}

	const getDateRange = () => {
		const startDate = new Date(album.assets[0].createdAt);
		const endDate = new Date(album.assets[album.assets.length - 1].createdAt);

		const timeFormatOption: Intl.DateTimeFormatOptions = {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		};

		const startDateString = startDate.toLocaleDateString('us-EN', timeFormatOption);
		const endDateString = endDate.toLocaleDateString('us-EN', timeFormatOption);
		return `${startDateString} - ${endDateString}`;
	};

	onMount(async () => {
		if (backUrl === '/sharing') {
			isCreatingSharedAlbum = true;
		}

		currentAlbumName = album.albumName;

		try {
			const { data } = await api.userApi.getMyUserInfo();
			currentUser = data;
		} catch (e) {
			console.log('Error [getMyUserInfo - album-viewer] ', e);
		}
	});

	const viewAssetHandler = (event: CustomEvent) => {
		const { asset }: { asset: AssetResponseDto } = event.detail;

		currentViewAssetIndex = album.assets.findIndex((a) => a.id == asset.id);
		selectedAsset = album.assets[currentViewAssetIndex];
		isShowAssetViewer = true;
		pushState(selectedAsset.id);
	};

	const selectAssetHandler = (event: CustomEvent) => {
		const { asset }: { asset: AssetResponseDto } = event.detail;
		let temp = new Set(multiSelectAsset);

		if (multiSelectAsset.has(asset)) {
			temp.delete(asset);
		} else {
			temp.add(asset);
		}

		multiSelectAsset = temp;
	};

	const clearMultiSelectAssetAssetHandler = () => {
		multiSelectAsset = new Set();
	};

	const removeSelectedAssetFromAlbum = async () => {
		if (window.confirm('Do you want to remove selected assets from the album?')) {
			try {
				const { data } = await api.albumApi.removeAssetFromAlbum(album.id, {
					assetIds: Array.from(multiSelectAsset).map((a) => a.id)
				});

				album = data;
				multiSelectAsset = new Set();
			} catch (e) {
				console.log('Error [album-viewer] [removeAssetFromAlbum]', e);
			}
		}
	};
	const navigateAssetForward = () => {
		try {
			if (currentViewAssetIndex < album.assets.length - 1) {
				currentViewAssetIndex++;
				selectedAsset = album.assets[currentViewAssetIndex];
				pushState(selectedAsset.id);
			}
		} catch (e) {
			console.error(e);
		}
	};

	const navigateAssetBackward = () => {
		try {
			if (currentViewAssetIndex > 0) {
				currentViewAssetIndex--;
				selectedAsset = album.assets[currentViewAssetIndex];
				pushState(selectedAsset.id);
			}
		} catch (e) {
			console.error(e);
		}
	};

	const pushState = (assetId: string) => {
		// add a URL to the browser's history
		// changes the current URL in the address bar but doesn't perform any SvelteKit navigation
		history.pushState(null, '', `${$page.url.pathname}/photos/${assetId}`);
	};

	const closeViewer = () => {
		isShowAssetViewer = false;
		history.pushState(null, '', `${$page.url.pathname}`);
	};

	// Update Album Name
	$: {
		if (!isEditingTitle && currentAlbumName != album.albumName && isOwned) {
			api.albumApi
				.updateAlbumInfo(album.id, {
					ownerId: album.ownerId,
					albumName: album.albumName
				})
				.then(() => {
					currentAlbumName = album.albumName;
				})
				.catch((e) => {
					console.log('Error [updateAlbumInfo] ', e);
				});
		}
	}

	const createAlbumHandler = async (event: CustomEvent) => {
		const { assets }: { assets: string[] } = event.detail;

		try {
			const { data } = await api.albumApi.addAssetsToAlbum(album.id, { assetIds: assets });
			album = data;

			isShowAssetSelection = false;
		} catch (e) {
			console.log('Error [createAlbumHandler] ', e);
		}
	};

	const addUserHandler = async (event: CustomEvent) => {
		const { selectedUsers }: { selectedUsers: UserResponseDto[] } = event.detail;

		try {
			const { data } = await api.albumApi.addUsersToAlbum(album.id, {
				sharedUserIds: Array.from(selectedUsers).map((u) => u.id)
			});

			album = data;

			isShowShareUserSelection = false;
		} catch (e) {
			console.log('Error [createAlbumHandler] ', e);
		}
	};

	const sharedUserDeletedHandler = async (event: CustomEvent) => {
		const { userId }: { userId: string } = event.detail;

		if (userId == 'me') {
			isShowShareInfoModal = false;
			goto(backUrl);
		}

		try {
			const { data } = await api.albumApi.getAlbumInfo(album.id);

			album = data;
			isShowShareInfoModal = false;
		} catch (e) {
			console.log('Error [sharedUserDeletedHandler] ', e);
		}
	};

	const removeAlbum = async () => {
		if (
			window.confirm(
				`Are you sure you want to delete album ${album.albumName}? If the album is shared, other users will not be able to access it.`
			)
		) {
			try {
				await api.albumApi.deleteAlbum(album.id);
				goto(backUrl);
			} catch (e) {
				console.log('Error [userDeleteMenu] ', e);
			}
		}
	};
</script>

<section class="bg-immich-bg">
	<!-- Multiselection mode app bar -->
	{#if isMultiSelectionMode}
		<AlbumAppBar
			on:close-button-click={clearMultiSelectAssetAssetHandler}
			backIcon={Close}
			tailwindClasses={'bg-white shadow-md'}
		>
			<svelte:fragment slot="leading">
				<p class="font-medium text-immich-primary">Selected {multiSelectAsset.size}</p>
			</svelte:fragment>
			<svelte:fragment slot="trailing">
				{#if isOwned}
					<CircleIconButton
						title="Remove from album"
						on:click={removeSelectedAssetFromAlbum}
						logo={DeleteOutline}
					/>
				{/if}
			</svelte:fragment>
		</AlbumAppBar>
	{/if}

	<!-- Default app bar -->
	{#if !isMultiSelectionMode}
		<AlbumAppBar on:close-button-click={() => goto(backUrl)} backIcon={ArrowLeft}>
			<svelte:fragment slot="trailing">
				{#if album.assets.length > 0}
					<CircleIconButton
						title="Add Photos"
						on:click={() => (isShowAssetSelection = true)}
						logo={FileImagePlusOutline}
					/>

					<!-- Sharing only for owner -->
					{#if isOwned}
						<CircleIconButton
							title="Share"
							on:click={() => (isShowShareUserSelection = true)}
							logo={ShareVariantOutline}
						/>
						<CircleIconButton title="Remove album" on:click={removeAlbum} logo={DeleteOutline} />
					{/if}
				{/if}

				{#if isCreatingSharedAlbum && album.sharedUsers.length == 0}
					<button
						disabled={album.assets.length == 0}
						on:click={() => (isShowShareUserSelection = true)}
						class="immich-text-button border bg-immich-primary text-gray-50 hover:bg-immich-primary/75 px-6 text-sm disabled:opacity-25 disabled:bg-gray-500 disabled:cursor-not-allowed"
						><span class="px-2">Share</span></button
					>
				{/if}
			</svelte:fragment>
		</AlbumAppBar>
	{/if}

	<section class="m-auto my-[160px] w-[60%]">
		<input
			on:focus={() => (isEditingTitle = true)}
			on:blur={() => (isEditingTitle = false)}
			class={`transition-all text-6xl text-immich-primary w-[99%] border-b-2 border-transparent outline-none ${
				isOwned ? 'hover:border-gray-400' : 'hover:border-transparent'
			} focus:outline-none focus:border-b-2 focus:border-immich-primary bg-immich-bg`}
			type="text"
			bind:value={album.albumName}
			disabled={!isOwned}
		/>

		{#if album.assets.length > 0}
			<p class="my-4 text-sm text-gray-500 font-medium">{getDateRange()}</p>
		{/if}

		{#if album.shared}
			<div class="my-6 flex">
				{#each album.sharedUsers as user}
					{#key user.id}
						<span class="mr-1">
							<CircleAvatar {user} on:click={() => (isShowShareInfoModal = true)} />
						</span>
					{/key}
				{/each}

				<button
					style:display={isOwned ? 'block' : 'none'}
					on:click={() => (isShowShareUserSelection = true)}
					title="Add more users"
					class="h-12 w-12 border bg-white transition-colors hover:bg-gray-300 text-3xl flex place-items-center place-content-center rounded-full"
					>+</button
				>
			</div>
		{/if}

		{#if album.assets.length > 0}
			<div class="flex flex-wrap gap-1 w-full pb-20" bind:clientWidth={viewWidth}>
				{#each album.assets as asset}
					{#key asset.id}
						{#if album.assets.length < 7}
							<ImmichThumbnail
								{asset}
								{thumbnailSize}
								format={ThumbnailFormat.Jpeg}
								on:click={(e) =>
									isMultiSelectionMode ? selectAssetHandler(e) : viewAssetHandler(e)}
								on:select={selectAssetHandler}
								selected={multiSelectAsset.has(asset)}
							/>
						{:else}
							<ImmichThumbnail
								{asset}
								{thumbnailSize}
								on:click={(e) =>
									isMultiSelectionMode ? selectAssetHandler(e) : viewAssetHandler(e)}
								on:select={selectAssetHandler}
								selected={multiSelectAsset.has(asset)}
							/>
						{/if}
					{/key}
				{/each}
			</div>
		{:else}
			<!-- Album is empty - Show asset selectection buttons -->
			<section id="empty-album" class=" mt-[200px] flex place-content-center place-items-center">
				<div class="w-[300px]">
					<p class="text-xs">ADD PHOTOS</p>
					<button
						on:click={() => (isShowAssetSelection = true)}
						class="w-full py-8 border bg-white rounded-md mt-5 flex place-items-center gap-6 px-8 transition-all hover:bg-gray-100 hover:text-immich-primary"
					>
						<span><Plus color="#4250af" size="24" /> </span>
						<span class="text-lg text-immich-fg">Select photos</span>
					</button>
				</div>
			</section>
		{/if}
	</section>
</section>

<!-- Overlay Asset Viewer -->
{#if isShowAssetViewer}
	<AssetViewer
		asset={selectedAsset}
		on:navigate-backward={navigateAssetBackward}
		on:navigate-forward={navigateAssetForward}
		on:close={closeViewer}
	/>
{/if}

{#if isShowAssetSelection}
	<AssetSelection
		assetsInAlbum={album.assets}
		on:go-back={() => (isShowAssetSelection = false)}
		on:create-album={createAlbumHandler}
	/>
{/if}

{#if isShowShareUserSelection}
	<UserSelectionModal
		on:close={() => (isShowShareUserSelection = false)}
		on:add-user={addUserHandler}
		sharedUsersInAlbum={new Set(album.sharedUsers)}
	/>
{/if}

{#if isShowShareInfoModal}
	<ShareInfoModal
		on:close={() => (isShowShareInfoModal = false)}
		{album}
		on:user-deleted={sharedUserDeletedHandler}
	/>
{/if}
