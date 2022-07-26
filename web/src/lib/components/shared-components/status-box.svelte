<script lang="ts">
	import { onDestroy, onMount } from 'svelte';
	import Cloud from 'svelte-material-icons/Cloud.svelte';
	import Dns from 'svelte-material-icons/Dns.svelte';
	import LoadingSpinner from './loading-spinner.svelte';
	import { api } from '@api';
	import { page } from '$app/stores';

	type ServerInfoType = {
		diskAvailable: string;
		diskAvailableRaw: number;
		diskSize: string;
		diskSizeRaw: number;
		diskUsagePercentage: number;
		diskUse: string;
		diskUseRaw: number;
	};

	let isServerOk = true;
	let serverVersion = '';
	let serverInfoRes: ServerInfoType;

	onMount(async () => {
		console.log($page);
		const serverVersionResponse = await api.serverInfoApi.getServerVersion();
		serverVersion = `v${serverVersionResponse.data.major}.${serverVersionResponse.data.minor}.${serverVersionResponse.data.patch}`;

		serverInfoRes = (await api.serverInfoApi.getServerInfo()).data;

		getStorageUsagePercentage();
	});

	const pingServerInterval = setInterval(async () => {
		const response = await api.serverInfoApi.pingServer();

		if (response.data.res === 'pong') isServerOk = true;
		else isServerOk = false;

		serverInfoRes = (await api.serverInfoApi.getServerInfo()).data;
	}, 10000);

	onDestroy(() => clearInterval(pingServerInterval));

	const getStorageUsagePercentage = () => {
		return Math.round((serverInfoRes.diskUseRaw / serverInfoRes.diskSizeRaw) * 100);
	};
</script>

<div>
	<div class="storage-status grid grid-cols-[64px_auto]">
		<div class="pl-5 pr-6 text-immich-primary">
			<Cloud size={'24'} />
		</div>
		<div>
			<p class="text-sm font-medium text-immich-primary">Storage</p>
			{#if serverInfoRes}
				<div class="w-full bg-gray-200 rounded-full h-[7px] dark:bg-gray-700 my-2">
					<!-- style={`width: ${$downloadAssets[fileName]}%`} -->
					<div
						class="bg-immich-primary h-[7px] rounded-full"
						style={`width: ${getStorageUsagePercentage()}%`}
					/>
				</div>
				<p class="text-xs">{serverInfoRes?.diskUse} of {serverInfoRes?.diskSize} used</p>
			{:else}
				<div class="mt-2">
					<LoadingSpinner />
				</div>
			{/if}
		</div>
	</div>
	<div>
		<hr class="ml-5 my-4" />
	</div>
	<div class="server-status grid grid-cols-[64px_auto]">
		<div class="pl-5 pr-6 text-immich-primary">
			<Dns size={'24'} />
		</div>

		<div class="text-xs">
			<p class="text-sm font-medium text-immich-primary">Server</p>

			<input
				class="border p-2 rounded-md bg-gray-200 mt-2 text-immich-primary font-medium"
				value={$page.url.origin}
				disabled={true}
			/>
			<div class="flex justify-items-center justify-between mt-2">
				<p>Status</p>

				{#if isServerOk}
					<p class="font-medium text-immich-primary">Online</p>
				{:else}
					<p class="font-medium text-red-500">Offline</p>
				{/if}
			</div>

			<div class="flex justify-items-center justify-between mt-2">
				<p>Version</p>
				<p class="font-medium text-immich-primary">{serverVersion}</p>
			</div>
		</div>
	</div>
	<!-- <div>
		<hr class="ml-5 my-4" />
	</div>
	<button class="text-xs ml-5 underline hover:cursor-pointer text-immich-primary" on:click={() => goto('/changelog')}
		>Changelog</button
	> -->
</div>
