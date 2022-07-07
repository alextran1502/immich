<script lang="ts">
	import { goto } from '$app/navigation';
	import { fade } from 'svelte/transition';

	import LoginForm from '$lib/components/forms/login-form.svelte';

	import {
		AuthorizationRequest,
		AuthorizationServiceConfiguration,
		FetchRequestor, LocalStorageBackend,
		RedirectRequestHandler
	} from "@openid/appauth";
	import {onMount} from "svelte";
	import {serverEndpoint} from "../../../lib/constants";

	let authConfig: AuthorizationServiceConfiguration;
	let localLoginEnabled = true;
	let oauth2LoginEnabled = false;
	let oauth2ClientId: string;

	onMount(async () => {

		const resLoginParams = await fetch(`${serverEndpoint}/auth/loginParams`);

		if (!resLoginParams.ok) {
			console.log('Cannot get login params');
			return;
		}

		let {localAuth, oauth2, issuer, clientId} = await resLoginParams.json();
		localLoginEnabled = localAuth;
		oauth2LoginEnabled = oauth2;
		oauth2ClientId = clientId;

		if (!oauth2LoginEnabled) {
			return;
		}

		if (issuer.endsWith('/'))
			issuer = issuer.substring(0, issuer.length-1);

		AuthorizationServiceConfiguration.fetchFromIssuer(
				issuer,
				new FetchRequestor()
		).then(response => {
			authConfig = response;
			localStorage.setItem('oauth2Config', JSON.stringify(authConfig));
			console.log("Fetched service configuration", response);
		});
	})

	const onLoginSuccess = async () => {
		goto('/photos');
	};

	const onOAuth2Login = () => {
		const request = new AuthorizationRequest({
			client_id: oauth2ClientId,
			redirect_uri: `${window.location.origin}/auth/callback`,
			scope: 'profile openid email',
			response_type: 'code id_token token',
			state: undefined, // generate random state for CSRF protection
		});

		let handler = new RedirectRequestHandler(new LocalStorageBackend(window.localStorage));

		handler.performAuthorizationRequest(authConfig, request);
	};
</script>

<svelte:head>
	<title>Immich - Login</title>
</svelte:head>

<section class="h-screen w-screen flex place-items-center place-content-center">
	<div in:fade={{ duration: 100 }} out:fade={{ duration: 100 }}>
		<LoginForm
				on:success={onLoginSuccess}
				on:first-login={() => goto('/auth/change-password')}
				on:oauth2-login={onOAuth2Login}
				{localLoginEnabled}
				{oauth2LoginEnabled} />
	</div>
</section>
