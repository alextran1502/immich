<script lang="ts">
	import { session } from '$app/stores';
	import { sendLoginForm } from '$lib/auth-api';
	import { createEventDispatcher } from 'svelte';

	export let localLoginEnabled: boolean;
	export let oauth2LoginEnabled: boolean;

	let error: string;
	const dispatch = createEventDispatcher();

	async function login(event: SubmitEvent) {
		error = '';

		const formElement = event.target as HTMLFormElement;

		const response = await sendLoginForm(formElement);

		if (response.error) {
			error = response.error;
		}

		if (response.success) {
			$session.user = {
				accessToken: response.user!.accessToken,
				firstName: response.user!.firstName,
				lastName: response.user!.lastName,
				isAdmin: response.user!.isAdmin,
				id: response.user!.id,
				email: response.user!.email,
			};

			if (!response.user?.isAdmin && response.user?.shouldChangePassword) {
				return dispatch('first-login');
			}

			return dispatch('success');
		}
	}

	async function loginOauth2() {
		return dispatch('oauth2-login');
	}
</script>

<div class="border bg-white p-4 shadow-sm w-[500px] rounded-md py-8">
	<div class="flex flex-col place-items-center place-content-center gap-4 px-4">
		<img class="text-center" src="/immich-logo.svg" height="100" width="100" alt="immich-logo" />
		<h1 class="text-2xl text-immich-primary font-medium">Login</h1>
	</div>

	{#if localLoginEnabled}
		<form on:submit|preventDefault={login} method="post" action="" autocomplete="off" >
			<div class="m-4 flex flex-col gap-2">
				<label class="immich-form-label" for="email">Email</label>
				<input class="immich-form-input" id="email" name="email" type="email" required />
			</div>

			<div class="m-4 flex flex-col gap-2">
				<label class="immich-form-label" for="password">Password</label>
				<input class="immich-form-input" id="password" name="password" type="password" required />
			</div>

			{#if error}
				<p class="text-red-400 pl-4">{error}</p>
			{/if}

			<div class="flex w-full">
				<button
					type="submit"
					class="m-4 p-2 bg-immich-primary hover:bg-immich-primary/75 px-6 py-4 text-white rounded-md shadow-md w-full font-semibold"
					>Login</button>
			</div>
		</form>
	{/if}

	{#if oauth2LoginEnabled}
		<div class="flex w-full">
			<button
					on:click={loginOauth2}
					type="submit"
					class="m-4 p-2 bg-immich-primary hover:bg-immich-primary/75 px-6 py-4 text-white rounded-md shadow-md w-full font-semibold"
			>OAuth2 Login</button>
		</div>
	{/if}
</div>
