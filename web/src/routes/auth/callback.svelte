<script lang="ts">
    import {
        AuthorizationNotifier,
        BaseTokenRequestHandler,
        FetchRequestor,
        GRANT_TYPE_AUTHORIZATION_CODE,
        LocalStorageBackend,
        RedirectRequestHandler,
        TokenRequest
    } from "@openid/appauth";
    import { onMount } from "svelte";
    import { goto } from "$app/navigation";
    import {session} from "$app/stores";

    let accessToken: string;
    let refreshToken: string;
    let redirectUri: string;

    const makeRefreshTokenRequest = async (code: string, codeVerifier: string|undefined, clientId: string, redirectUri: string) => {
        let authConfig = JSON.parse(localStorage.getItem('oauth2Config'));

        // use the code to make the token request.
        let request = new TokenRequest({
            client_id: clientId,
            redirect_uri: redirectUri,
            grant_type: GRANT_TYPE_AUTHORIZATION_CODE,
            code: code,
            refresh_token: undefined,
            extras: {
                code_verifier: codeVerifier
            }
        });

        await (new BaseTokenRequestHandler(new FetchRequestor()))
            .performTokenRequest(authConfig, request)
            .then(response => {
                accessToken = response.idToken;
                refreshToken = response.refreshToken;
            })
            .then(async () => {
                let data = new URLSearchParams({
                    'id_token': accessToken,
                });

                const res = await fetch(redirectUri, {
                    method: 'POST',
                    headers: new Headers({
                        'Content-Type': 'application/x-www-form-urlencoded',
                        'Accept': 'application/json',
                    }),
                    body: data,
                });

                const response = await res.json();

                $session.user = {
                    accessToken: response.user!.accessToken,
                    firstName: response.user!.firstName,
                    lastName: response.user!.lastName,
                    isAdmin: response.user!.isAdmin,
                    id: response.user!.id,
                    email: response.user!.email,
                };
            });
    }

    onMount(async () => {
        let handler = new RedirectRequestHandler(new LocalStorageBackend(window.localStorage));
        let notifier = new AuthorizationNotifier();

        notifier.setAuthorizationListener((request, response, error) => {
            if (response) {
                let codeVerifier: string | undefined;
                if(request.internal && request.internal.code_verifier) {
                    codeVerifier = request.internal.code_verifier;
                }

                redirectUri = request.redirectUri;

                makeRefreshTokenRequest(response.code, codeVerifier, request.clientId, request.redirectUri)
                    .then(async () => {
                        console.log("Authentication with OAuth2 complete!");
                        await goto('/photos');
                    });
            }
        });

        handler.setAuthorizationNotifier(notifier);
        await handler.completeAuthorizationRequestIfPossible();
    });
</script>