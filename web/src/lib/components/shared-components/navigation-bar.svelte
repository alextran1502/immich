<script lang="ts">
	import { session } from '$app/stores';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { createEventDispatcher, onMount } from 'svelte';
	import { fade, fly, slide } from 'svelte/transition';
	import TrayArrowUp from 'svelte-material-icons/TrayArrowUp.svelte';
	import { clickOutside } from '../../utils/click-outside';
	import { api, UserResponseDto } from '@api';
	import { gotoLogin, logoutUser } from '$lib/user_auth';

	export let user: UserResponseDto;

	let shouldShowAccountInfo = false;
	let shouldShowProfileImage = false;

	const dispatch = createEventDispatcher();
	let shouldShowAccountInfoPanel = false;

	onMount(() => {
		getUserProfileImage();
	});

	const getUserProfileImage = async () => {
		try {
			await api.userApi.getProfileImage(user.id);
			shouldShowProfileImage = true;
		} catch (e) {
			console.log('User does not have a profile image');
			shouldShowProfileImage = false;
		}
	};
	const getFirstLetter = (text?: string) => {
		return text?.charAt(0).toUpperCase();
	};

	const navigateToAdmin = () => {
		goto('/admin');
	};

	const showAccountInfoPanel = () => {
		shouldShowAccountInfoPanel = true;
	};

	const logOut = async () => {
		logoutUser().then(() => gotoLogin());
	};
</script>

<section id="dashboard-navbar" class="fixed w-screen  z-[100] bg-immich-bg text-sm">
	<div class="flex border-b place-items-center px-6 py-2 ">
		<a sveltekit:prefetch class="flex gap-2 place-items-center hover:cursor-pointer" href="/photos">
			<img src="/immich-logo.svg" alt="immich logo" height="35" width="35" />
			<h1 class="font-immich-title text-2xl text-immich-primary">IMMICH</h1>
		</a>
		<div class="flex-1 ml-24">
			<input
				class="w-[50%] border rounded-md bg-gray-200 px-8 py-4"
				placeholder="Search - Coming soon"
			/>
		</div>
		<section class="flex gap-4 place-items-center">
			{#if $page.url.pathname !== '/admin'}
				<button
					in:fly={{ x: 50, duration: 250 }}
					on:click={() => dispatch('uploadClicked')}
					class="immich-text-button"
				>
					<TrayArrowUp size="20" />
					<span> Upload </span>
				</button>
			{/if}

			{#if user.isAdmin}
				<a sveltekit:prefetch href={`admin`}>
					<button
						class={`flex place-items-center place-content-center gap-2 hover:bg-immich-primary/5 p-2 rounded-lg font-medium ${
							$page.url.pathname == '/admin' && 'text-immich-primary underline'
						}`}>Administration</button
					>
				</a>
			{/if}

			<div
				on:mouseover={() => (shouldShowAccountInfo = true)}
				on:focus={() => (shouldShowAccountInfo = true)}
				on:mouseleave={() => (shouldShowAccountInfo = false)}
				on:click={showAccountInfoPanel}
			>
				<button
					class="flex place-items-center place-content-center rounded-full bg-immich-primary/80 h-12 w-12 text-gray-100 hover:bg-immich-primary"
				>
					{#if shouldShowProfileImage}
						<img
							src={`/api/user/profile-image/${user.id}`}
							alt="profile-img"
							class="inline rounded-full h-12 w-12 object-cover shadow-md"
						/>
					{:else}
						{getFirstLetter(user.firstName)}{getFirstLetter(user.lastName)}
					{/if}
				</button>

				{#if shouldShowAccountInfo}
					<div
						in:fade={{ delay: 500, duration: 150 }}
						out:fade={{ delay: 200, duration: 150 }}
						class="absolute -bottom-12 right-5 border bg-gray-500 text-[12px] text-gray-100 p-2 rounded-md shadow-md"
					>
						<p>{user.firstName} {user.lastName}</p>
						<p>{user.email}</p>
					</div>
				{/if}
			</div>
		</section>
	</div>

	{#if shouldShowAccountInfoPanel}
		<div
			in:fade={{ duration: 100 }}
			out:fade={{ duration: 100 }}
			id="account-info-panel"
			class="absolute right-[25px] top-[75px] bg-white shadow-lg rounded-2xl w-[360px] text-center"
			use:clickOutside
			on:out-click={() => (shouldShowAccountInfoPanel = false)}
		>
			<div class="flex place-items-center place-content-center mt-6">
				<button
					class="flex place-items-center place-content-center rounded-full bg-immich-primary/80 h-20 w-20 text-gray-100 hover:bg-immich-primary"
				>
					{#if shouldShowProfileImage}
						<img
							src={`/api/user/profile-image/${user.id}`}
							alt="profile-img"
							class="inline rounded-full h-20 w-20 object-cover shadow-md"
						/>
					{:else}
						<div class="text-lg">
							{getFirstLetter(user.firstName)}{getFirstLetter(user.lastName)}
						</div>
					{/if}
				</button>
			</div>

			<p class="text-lg text-immich-primary font-medium mt-4">
				{user.firstName}
				{user.lastName}
			</p>

			<p class="text-sm text-gray-500">{user.email}</p>

			<div class="my-4">
				<hr />
			</div>

			<div class="mb-6">
				<button class="border rounded-3xl px-6 py-2 hover:bg-gray-50" on:click={logOut}
					>Sign Out</button
				>
			</div>
		</div>
	{/if}
</section>
