import {
	AlbumApi,
	AssetApi,
	AuthenticationApi,
	Configuration,
	DeviceInfoApi,
	ServerInfoApi,
	UserApi
} from './open-api';

class ImmichApi {
	public userApi: UserApi;
	public albumApi: AlbumApi;
	public assetApi: AssetApi;
	public authenticationApi: AuthenticationApi;
	public deviceInfoApi: DeviceInfoApi;
	public serverInfoApi: ServerInfoApi;
	private config = new Configuration({ basePath: '/api' });

	constructor() {
		this.userApi = new UserApi(this.config);
		this.albumApi = new AlbumApi(this.config);
		this.assetApi = new AssetApi(this.config);
		this.authenticationApi = new AuthenticationApi(this.config);
		this.deviceInfoApi = new DeviceInfoApi(this.config);
		this.serverInfoApi = new ServerInfoApi(this.config);
	}

	public setAccessToken(accessToken: string) {
		this.config.accessToken = accessToken;
	}
}

export const api = new ImmichApi();
