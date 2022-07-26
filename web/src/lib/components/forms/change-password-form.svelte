<script lang="ts">
	import { api } from '@api';

	import { createEventDispatcher } from 'svelte';
	import type { ImmichUser } from '../../models/immich-user';

	export let user: ImmichUser;
	let error: string;
	let success: string;

	let password: string = '';
	let confirmPassowrd: string = '';

	let changeChagePassword = false;

	$: {
		if (password !== confirmPassowrd && confirmPassowrd.length > 0) {
			error = 'Password does not match';
			changeChagePassword = false;
		} else {
			error = '';
			changeChagePassword = true;
		}
	}
	const dispatch = createEventDispatcher();

	async function changePassword(event: SubmitEvent) {
		if (changeChagePassword) {
			error = '';

			const { status } = await api.userApi.updateUser({
				id: user.id,
				password: password,
				shouldChangePassword: false
			});

			if (status == 200) {
				dispatch('success');
			}
		}
	}
</script>

<div class="border bg-white p-4 shadow-sm w-[500px] rounded-md py-8">
	<div class="flex flex-col place-items-center place-content-center gap-4 px-4">
		<img class="text-center" src="/immich-logo.svg" height="100" width="100" alt="immich-logo" />
		<h1 class="text-2xl text-immich-primary font-medium">Chage Password</h1>

		<p class="text-sm border rounded-md p-4 font-mono text-gray-600">
			Hi {user.firstName}
			{user.lastName} ({user.email}),
			<br />
			<br />
			This is either the first time you are signing into the system or a request has been made to change your password. Please
			enter the new password below.
		</p>
	</div>

	<form on:submit|preventDefault={changePassword} method="post" autocomplete="off">
		<div class="m-4 flex flex-col gap-2">
			<label class="immich-form-label" for="password">New Password</label>
			<input class="immich-form-input" id="password" name="password" type="password" required bind:value={password} />
		</div>

		<div class="m-4 flex flex-col gap-2">
			<label class="immich-form-label" for="confirmPassword">Confirm Password</label>
			<input
				class="immich-form-input"
				id="confirmPassword"
				name="password"
				type="password"
				required
				bind:value={confirmPassowrd}
			/>
		</div>

		{#if error}
			<p class="text-red-400 ml-4 text-sm">{error}</p>
		{/if}

		{#if success}
			<p class="text-immich-primary ml-4 text-sm">{success}</p>
		{/if}
		<div class="flex w-full">
			<button
				type="submit"
				class="m-4 p-2 bg-immich-primary hover:bg-immich-primary/75 px-6 py-4 text-white rounded-md shadow-md w-full"
				>Change Password</button
			>
		</div>
	</form>
</div>
