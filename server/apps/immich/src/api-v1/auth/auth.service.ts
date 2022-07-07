import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import {InjectRepository} from '@nestjs/typeorm';
import {Repository} from 'typeorm';
import { UserEntity } from '@app/database/entities/user.entity';
import {LoginCredentialDto} from './dto/login-credential.dto';
import {ImmichJwtService} from '../../modules/immich-auth/immich-jwt.service';
import {SignUpDto} from './dto/sign-up.dto';
import {AuthUserDto} from "../../decorators/auth-user.decorator";
import { ConfigService } from '@nestjs/config';
import {ImmichAuthService} from "../../modules/immich-auth/immich-auth.service";
import {mapUser, UserResponseDto} from "../user/response-dto/user-response.dto";


@Injectable()
export class AuthService {

  constructor(
      @InjectRepository(UserEntity)
      private userRepository: Repository<UserEntity>,
      private immichAuthService: ImmichAuthService,
      private immichJwtService: ImmichJwtService,
      private configService: ConfigService,
  ) {}

  public async loginParams() {
    const params = {
      localAuth: true,
      oauth2: false,
      issuer: '',
      clientId: '',
    };

    if (this.configService.get<boolean>('OAUTH2_ENABLE') === true) {
      params.oauth2 = true;
      params.issuer =  this.configService.getOrThrow<string>('OAUTH2_ISSUER');
      params.clientId = this.configService.getOrThrow<string>('OAUTH2_CLIENT_ID');
    }

    if (this.configService.get<boolean>('LOCAL_USERS_DISABLE') === true) {
      params.localAuth = false;
    }

    return params;

  }

  async getWsToken(userId: string) {
    return {
      wsToken: await this.immichAuthService.generateWsToken(userId),
    };
  }

  public async adminSignUp(signUpCredential: SignUpDto): Promise<UserResponseDto> {
    if (this.configService.get<boolean>('LOCAL_USERS_DISABLE') === true) {
      throw new BadRequestException("Local users not allowed!");
    }

    try {
      const adminUser = await this.immichJwtService.signUpAdmin(signUpCredential.email, signUpCredential.password, signUpCredential.firstName, signUpCredential.lastName);
      return mapUser(adminUser);
    } catch (e) {
      Logger.error(`Failed to register new admin user: ${e}`, 'AUTH');
      throw new InternalServerErrorException('Failed to register new admin user');
    }
  }

  public async login(loginCredential: LoginCredentialDto) {
    if (this.configService.get<boolean>('LOCAL_USERS_DISABLE') === true) {
      throw new BadRequestException("Local users not allowed!");
    }

    return this.immichJwtService.validate(loginCredential.email, loginCredential.password);
  }
}
