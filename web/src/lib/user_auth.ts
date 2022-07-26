import { api, UserResponseDto } from '@api';
import { goto } from '$app/navigation';
import { get } from 'svelte/store';
import { session } from '$app/stores';

export async function checkUserAuthStatus(): Promise<UserResponseDto> {
	const user = get(session).user;
	if (user) return user;

	const { data } = await api.userApi.getMyUserInfo();

	session.update((sessionData) => {
		return {
			...sessionData,
			user: data
		};
	});

	return data;
}

export async function logoutUser(): Promise<void> {
	const { data } = await api.authenticationApi.logout();

	if (data.successful) {
		session.update((sessionData) => {
			return {
				...sessionData,
				user: undefined
			};
		});
	}
}

export function gotoLogin() {
	goto('/auth/login');
}
