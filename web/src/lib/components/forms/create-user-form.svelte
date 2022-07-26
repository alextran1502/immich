<script lang="ts">
	import { api } from '@api';

	import { createEventDispatcher } from 'svelte';

	let error: string;
	let success: string;

	let password: string = '';
	let confirmPassowrd: string = '';

	let firstName: string = '';
	let lastName: string = '';
	let email: string = '';

	let canCreateUser = false;

	$: {
		if (password !== confirmPassowrd && confirmPassowrd.length > 0) {
			error = 'Password does not match';
			canCreateUser = false;
		} else {
			error = '';
			canCreateUser = true;
		}
	}
	const dispatch = createEventDispatcher();

	async function registerUser(event: SubmitEvent) {
		if (canCreateUser) {
			error = '';

			try {
				await api.userApi.createUser({
					email,
					password,
					firstName,
					lastName
				});

				success = 'New user created';
				dispatch('user-created');
			} catch (e) {
				error = 'User creation failed';
				console.error('Error [create-user-form] [registerUser]', e);
			}
		}
	}
</script>

<div class="border bg-white p-4 shadow-sm w-[500px] rounded-md py-8">
	<div class="flex flex-col place-items-center place-content-center gap-4 px-4">
		<img class="text-center" src="/immich-logo.svg" height="100" width="100" alt="immich-logo" />
		<h1 class="text-2xl text-immich-primary font-medium">Create new user</h1>
		<p class="text-sm border rounded-md p-4 font-mono text-gray-600">
			Please provide your user with the password, they will have to change it on their first sign
			in.
		</p>
	</div>

	<form on:submit|preventDefault={registerUser} autocomplete="off">
		<div class="m-4 flex flex-col gap-2">
			<label class="immich-form-label" for="email">Email</label>
			<input
				class="immich-form-input"
				id="email"
				name="email"
				type="email"
				required
				bind:value={email}
			/>
		</div>

		<div class="m-4 flex flex-col gap-2">
			<label class="immich-form-label" for="password">Password</label>
			<input
				class="immich-form-input"
				id="password"
				name="password"
				type="password"
				required
				bind:value={password}
			/>
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

		<div class="m-4 flex flex-col gap-2">
			<label class="immich-form-label" for="firstName">First Name</label>
			<input
				class="immich-form-input"
				id="firstName"
				name="firstName"
				type="text"
				required
				bind:value={firstName}
			/>
		</div>

		<div class="m-4 flex flex-col gap-2">
			<label class="immich-form-label" for="lastName">Last Name</label>
			<input
				class="immich-form-input"
				id="lastName"
				name="lastName"
				type="text"
				required
				bind:value={lastName}
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
				>Create</button
			>
		</div>
	</form>
</div>
