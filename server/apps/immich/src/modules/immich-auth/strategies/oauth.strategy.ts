import {
    Injectable,
    Logger,
} from '@nestjs/common';
import {PassportStrategy} from '@nestjs/passport';
import {InjectRepository} from '@nestjs/typeorm';
import {ExtractJwt, Strategy} from 'passport-jwt';
import {Repository} from 'typeorm';
import {UserEntity} from "@app/database/entities/user.entity";
import {ImmichOauth2Service} from "../immich-oauth2.service";
import {ConfigService} from "@nestjs/config";

@Injectable()
export class Oauth2Strategy extends PassportStrategy(Strategy, 'oauth2') {
    constructor(
        @InjectRepository(UserEntity)
        private usersRepository: Repository<UserEntity>,
        private immichOauth2Service: ImmichOauth2Service,
        private configService: ConfigService,
    ) {
        super({
            jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
            ignoreExpiration: false,
            secretOrKey: Buffer.from(configService.getOrThrow<string>('OAUTH2_CERTIFICATE'), 'base64').toString('ascii'),
            audience: configService.get<string>('OAUTH2_CLIENT_ID'),
        });
    }

    async validate(payload: any) {
        Logger.verbose('Trying to validate OIDC id_token', 'OAUTH2 STRATEGY');
        return await this.immichOauth2Service.validateUserOauth(payload);
    }

}