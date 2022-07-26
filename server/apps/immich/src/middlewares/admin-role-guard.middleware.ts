import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserEntity } from '@app/database/entities/user.entity';
import { ImmichJwtService } from '../modules/immich-jwt/immich-jwt.service';

@Injectable()
export class AdminRolesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private jwtService: ImmichJwtService,
    @InjectRepository(UserEntity)
    private userRepository: Repository<UserEntity>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    let accessToken = '';

    if (request.headers['authorization']) {
      accessToken = request.headers['authorization'].split(' ')[1];
    } else if (request.cookies['immich_access_token']) {
      accessToken = request.cookies['immich_access_token'];
    } else {
      return false;
    }

    const { userId } = await this.jwtService.validateToken(accessToken);

    if (!userId) {
      return false;
    }

    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      return false;
    }

    return user.isAdmin;
  }
}
