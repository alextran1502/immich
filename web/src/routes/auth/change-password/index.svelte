<script lang="ts">
	import { goto } from '$app/navigation';
	import { fade } from 'svelte/transition';
	import { session } from '$app/stores';

	import ChangePasswordForm from '$lib/components/forms/change-password-form.svelte';
	import { api, UserResponseDto } from '@api';
	import { checkUserAuthStatus, gotoLogin, logoutUser } from '$lib/user_auth';

	checkUserAuthStatus().catch(() => {
		gotoLogin();
	});

	const onSuccessHandler = async () => {
		logoutUser().then(() => gotoLogin());
	};
</script>

<svelte:head>
	<title>Change Password - Immich</title>
</svelte:head>

<section class="h-screen w-screen flex place-items-center place-content-center">
	{#if $session.user}
		<div in:fade={{ duration: 100 }} out:fade={{ duration: 100 }}>
			<ChangePasswordForm user={$session.user} on:success={onSuccessHandler} />
		</div>
	{:else}
		Not logged in.
	{/if}
</section>
