import {BadRequestException, Injectable, InternalServerErrorException, Logger} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { JwtPayloadDto } from '../../api-v1/auth/dto/jwt-payload.dto';
import { jwtSecret } from '../../constants/jwt.constant';
import * as bcrypt from 'bcrypt';
import {UserEntity} from "@app/database/entities/user.entity";
import { Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { ImmichAuthService } from './immich-auth.service';
import {mapUser} from "../../api-v1/user/response-dto/user-response.dto";

@Injectable()
export class ImmichJwtService {
  constructor(
    @InjectRepository(UserEntity)
    private userRepository: Repository<UserEntity>,
    private jwtService: JwtService,
    private immichAuthService: ImmichAuthService,
  ) {}

  public async generateToken(payload: JwtPayloadDto) {
    return this.jwtService.sign({
      ...payload,
    });
  }

  public async validateToken(accessToken: string) {
    try {
      const payload = await this.jwtService.verify(accessToken, { secret: jwtSecret });
      return {
        userId: payload['userId'],
        status: true,
      };
    } catch (e) {
      Logger.error('Error validating token from websocket request', 'ValidateWebsocketToken');
      return {
        userId: null,
        status: false,
      };
    }
  }

  private async validateLocalUser(email: string, password: string): Promise<UserEntity | undefined> {
    const user = await this.userRepository.findOne(
        { where:
                  { email: email },
                 select: [
                      'id',
                      'email',
                      'password',
                      'salt',
                      'firstName',
                      'lastName',
                      'isAdmin',
                      'profileImagePath',
                      'shouldChangePassword',
                      'isLocalUser',
                    ],
                  },
    );

    if (!user || !user.isLocalUser) {
        throw new BadRequestException('Incorrect email or password');
    }

    if (!user.password || !user.salt) {
        throw new InternalServerErrorException();
    }

    const isAuthenticated = await ImmichJwtService.validatePassword(user.password, password, user.salt);

    if (user && isAuthenticated) {
      return user;
    }

    return undefined;
  }

  async validate(email: string, password: string) {

    const validatedUser = await this.validateLocalUser(email, password);
    if (!validatedUser) {
        throw new BadRequestException('Incorrect email or password');
    }

    const payload = new JwtPayloadDto(validatedUser.id, validatedUser.email);

    return {
      accessToken: await this.generateToken(payload),
        userId: validatedUser.id,
        userEmail: validatedUser.email,
        firstName: validatedUser.firstName,
        lastName: validatedUser.lastName,
        isAdmin: validatedUser.isAdmin,
        profileImagePath: validatedUser.profileImagePath,
        shouldChangePassword: validatedUser.shouldChangePassword,
    };
  }

  private static async validatePassword(hashedPassword: string, inputPassword: string, salt: string): Promise<boolean> {
    const hash = await bcrypt.hash(inputPassword, salt);
    return hash === hashedPassword;
  }

  async signUpAdmin(email: string, password: string, firstName: string, lastName: string) {
    return await this.immichAuthService.createAdmin(email, true, password, firstName, lastName);
  }
}