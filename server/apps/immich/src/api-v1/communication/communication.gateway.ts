import { OnGatewayConnection, OnGatewayDisconnect, WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Socket, Server } from 'socket.io';
import { Logger } from '@nestjs/common';
import { UserEntity } from '@app/database/entities/user.entity';
import {ImmichAuthService} from "../../modules/immich-auth/immich-auth.service";

@WebSocketGateway({ cors: true })
export class CommunicationGateway implements OnGatewayConnection, OnGatewayDisconnect {
  constructor(
    private immichAuthService: ImmichAuthService,
  ) {}

  @WebSocketServer() server!: Server;

  handleDisconnect(client: Socket) {
    client.leave(client.nsp.name);

    Logger.log(`Client ${client.id} disconnected from Websocket`, 'WebsocketConnectionEvent');
  }

  async handleConnection(client: Socket, ...args: any[]) {
    Logger.verbose(`New websocket connection: ${client.id}`, 'WebsocketConnectionEvent');

      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const authBearer = client.handshake.headers.authorization!;
    if (!authBearer.startsWith('Bearer '))  {
      client.emit('error', 'unauthorized');
      client.disconnect();
      return;
    }

    const accessToken = authBearer.substring(7);
    const user: UserEntity | undefined = await this.immichAuthService.validateWsToken(accessToken);

    if (!user) {
      client.emit('error', 'unauthorized');
      client.disconnect();
      return;
    }

    Logger.log(`New webocket connection (client id: ${client.id}, user id: ${user.id})`, 'WebsocketConnectionEvent');
    client.join(user.id);
  }
}
