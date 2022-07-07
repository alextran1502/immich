import { Socket, io } from 'socket.io-client';
import { writable } from 'svelte/store';
import { serverEndpoint } from '../constants';
import type { ImmichAsset } from '../models/immich-asset';
import { assets } from './assets';

let websocket: Socket;

export const openWebsocketConnection = (accessToken: string) => {

	const websocketEndpoint = new URL(serverEndpoint + '/socket.io');

	try {
		const websocket = io(websocketEndpoint.origin, {
			path: websocketEndpoint.pathname,
			transports: ['polling'],
			reconnection: true,
			forceNew: true,
			autoConnect: true,
			extraHeaders: {
				Authorization: 'Bearer ' + accessToken,
			},
		});

		listenToEvent(websocket);
	} catch (e) {
		console.log('Cannot connect to websocket ', e);
	}
};

const listenToEvent = (socket: Socket) => {
	socket.on('on_upload_success', (data) => {
		const newUploadedAsset: ImmichAsset = JSON.parse(data);
		// assets.update((assets) => [...assets, newUploadedAsset]);
	});

	socket.on('error', (e) => {
		console.log('Websocket Error', e);
	});
};

export const closeWebsocketConnection = () => {
	websocket?.close();
};
