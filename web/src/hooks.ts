import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
	console.log('HANDLE', event.routeId);
	return await resolve(event, { ssr: false });
};
