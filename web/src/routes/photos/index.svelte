<script lang="ts">
	import NavigationBar from '$lib/components/shared-components/navigation-bar.svelte';
	import CheckCircle from 'svelte-material-icons/CheckCircle.svelte';
	import { fly } from 'svelte/transition';
	import { session } from '$app/stores';
	import { assetsGroupByDate, flattenAssetGroupByDate, getAssetsInfo } from '$lib/stores/assets';
	import ImmichThumbnail from '$lib/components/shared-components/immich-thumbnail.svelte';
	import moment from 'moment';
	import AssetViewer from '$lib/components/asset-viewer/asset-viewer.svelte';
	import { fileUploader } from '$lib/utils/file-uploader';
	import { AssetResponseDto } from '@api';
	import SideBar from '$lib/components/shared-components/side-bar/side-bar.svelte';
	import { checkUserAuthStatus, gotoLogin } from '$lib/user_auth';

	let selectedGroupThumbnail: number | null;
	let isMouseOverGroup: boolean;

	$: if (isMouseOverGroup == false) {
		selectedGroupThumbnail = null;
	}

	let isShowAssetViewer = false;
	let currentViewAssetIndex = 0;
	let selectedAsset: AssetResponseDto;

	checkUserAuthStatus()
		.then(() => {
			getAssetsInfo();
		})
		.catch(() => {
			gotoLogin();
		});

	const thumbnailMouseEventHandler = (event: CustomEvent) => {
		const { selectedGroupIndex }: { selectedGroupIndex: number } = event.detail;

		selectedGroupThumbnail = selectedGroupIndex;
	};

	const viewAssetHandler = (event: CustomEvent) => {
		const { asset }: { asset: AssetResponseDto } = event.detail;

		currentViewAssetIndex = $flattenAssetGroupByDate.findIndex((a) => a.id == asset.id);
		selectedAsset = $flattenAssetGroupByDate[currentViewAssetIndex];
		isShowAssetViewer = true;
		pushState(selectedAsset.id);
	};

	const uploadClickedHandler = async () => {
		if ($session.user) {
			try {
				let fileSelector = document.createElement('input');

				fileSelector.type = 'file';
				fileSelector.multiple = true;
				fileSelector.accept = 'image/*,video/*,.heic,.heif';

				fileSelector.onchange = async (e: any) => {
					const files = Array.from<File>(e.target.files);

					const acceptedFile = files.filter(
						(e) => e.type.split('/')[0] === 'video' || e.type.split('/')[0] === 'image'
					);

					for (const asset of acceptedFile) {
						await fileUploader(asset);
					}
				};

				fileSelector.click();
			} catch (e) {
				console.log('Error seelcting file', e);
			}
		}
	};

	const navigateAssetForward = () => {
		try {
			if (currentViewAssetIndex < $flattenAssetGroupByDate.length - 1) {
				currentViewAssetIndex++;
				selectedAsset = $flattenAssetGroupByDate[currentViewAssetIndex];
				pushState(selectedAsset.id);
			}
		} catch (e) {
			console.log('Error navigating asset forward', e);
		}
	};

	const navigateAssetBackward = () => {
		try {
			if (currentViewAssetIndex > 0) {
				currentViewAssetIndex--;
				selectedAsset = $flattenAssetGroupByDate[currentViewAssetIndex];
				pushState(selectedAsset.id);
			}
		} catch (e) {
			console.log('Error navigating asset backward', e);
		}
	};

	const pushState = (assetId: string) => {
		// add a URL to the browser's history
		// changes the current URL in the address bar but doesn't perform any SvelteKit navigation
		history.pushState(null, '', `/photos/${assetId}`);
	};

	const closeViewer = () => {
		isShowAssetViewer = false;
		history.pushState(null, '', `/photos`);
	};
</script>

<svelte:head>
	<title>Photos - Immich</title>
</svelte:head>

<section>
	{#if $session.user}
		<NavigationBar user={$session.user} on:uploadClicked={uploadClickedHandler} />
	{/if}
</section>

<section class="grid grid-cols-[250px_auto] relative pt-[72px] h-screen bg-immich-bg">
	<SideBar />

	<!-- Main Section -->
	<section class="overflow-y-auto relative immich-scrollbar">
		<section id="assets-content" class="relative pt-8 pl-4 mb-12 bg-immich-bg">
			<section id="image-grid" class="flex flex-wrap gap-14">
				{#each $assetsGroupByDate as assetsInDateGroup, groupIndex}
					<!-- Asset Group By Date -->
					<div
						class="flex flex-col"
						on:mouseenter={() => (isMouseOverGroup = true)}
						on:mouseleave={() => (isMouseOverGroup = false)}
					>
						<!-- Date group title -->
						<p class="font-medium text-sm text-immich-fg mb-2 flex place-items-center h-6">
							{#if selectedGroupThumbnail === groupIndex && isMouseOverGroup}
								<div
									in:fly={{ x: -24, duration: 200, opacity: 0.5 }}
									out:fly={{ x: -24, duration: 200 }}
									class="inline-block px-2 hover:cursor-pointer"
								>
									<CheckCircle size="24" color="#757575" />
								</div>
							{/if}

							{moment(assetsInDateGroup[0].createdAt).format('ddd, MMM DD YYYY')}
						</p>

						<!-- Image grid -->
						<div class="flex flex-wrap gap-[2px]">
							{#each assetsInDateGroup as asset}
								{#key asset.id}
									<ImmichThumbnail
										{asset}
										on:mouseEvent={thumbnailMouseEventHandler}
										on:click={viewAssetHandler}
										{groupIndex}
									/>
								{/key}
							{/each}
						</div>
					</div>
				{/each}
			</section>
		</section>
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
