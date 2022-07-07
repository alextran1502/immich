import {Injectable, Logger, UnauthorizedException} from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { InjectRepository } from '@nestjs/typeorm';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { Repository } from 'typeorm';
import { JwtPayloadDto } from '../../../api-v1/auth/dto/jwt-payload.dto';
import { UserEntity } from '@app/database/entities/user.entity';
import { jwtSecret } from '../../../constants/jwt.constant';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    @InjectRepository(UserEntity)
    private usersRepository: Repository<UserEntity>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: jwtSecret,
    });
  }

  async validate(payload: JwtPayloadDto) {
    Logger.verbose('Trying to validate JWT token', 'JWT STRATEGY');

    const { userId } = payload;
    const user = await this.usersRepository.findOne({ where: { id: userId } });

    if (!user || !user.isLocalUser) {
      throw new UnauthorizedException('Failure to validate JWT payload');
    }

    Logger.verbose(`Validated user with email ${user.email}`, "JWT STRATEGY");
    return user;
  }
}