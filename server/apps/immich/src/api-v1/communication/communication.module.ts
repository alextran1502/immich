import { Module } from '@nestjs/common';
import { CommunicationService } from './communication.service';
import { CommunicationGateway } from './communication.gateway';
import { ImmichAuthModule } from '../../modules/immich-auth/immich-auth.module';
import { ImmichJwtService } from '../../modules/immich-auth/immich-jwt.service';
import { JwtModule } from '@nestjs/jwt';
import { jwtConfig } from '../../config/jwt.config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserEntity } from '@app/database/entities/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([UserEntity]), ImmichAuthModule.register(), JwtModule.register(jwtConfig)],
  providers: [CommunicationGateway, CommunicationService, ImmichJwtService],
  exports: [CommunicationGateway],
})
export class CommunicationModule {}
