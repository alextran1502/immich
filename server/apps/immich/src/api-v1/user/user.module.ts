import { Module } from '@nestjs/common';
import { UserService } from './user.service';
import { UserController } from './user.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserEntity } from '@app/database/entities/user.entity';
import { JwtModule } from '@nestjs/jwt';
import { jwtConfig } from '../../config/jwt.config';
import {ImmichAuthModule} from "../../modules/immich-auth/immich-auth.module";
import {ImmichAuthService} from "../../modules/immich-auth/immich-auth.service";

@Module({
  imports: [TypeOrmModule.forFeature([UserEntity]), ImmichAuthModule.register(), JwtModule.register(jwtConfig)],
  controllers: [UserController],
  providers: [UserService, ImmichAuthService],
})
export class UserModule {}
