import {
    BadRequestException,
    Injectable,
    InternalServerErrorException,
    Logger
} from '@nestjs/common';
import {InjectRepository} from "@nestjs/typeorm";
import {UserEntity} from "@app/database/entities/user.entity";
import {Repository} from "typeorm";
import { ImmichAuthService } from './immich-auth.service';

@Injectable()
export class ImmichOauth2Service {

  constructor(
      @InjectRepository(UserEntity)
      private userRepository: Repository<UserEntity>,
      private immichAuthService: ImmichAuthService,
  ) {}

  public async validateUserOauth(payload: any) {
    const email = payload.email;
    if (!email || email === "") {
        throw new BadRequestException("User email not found");
    }

    const user = await this.userRepository.findOne({ where: { email: email }});

    const firstName = payload.given_name || '';
    const lastName = payload.family_name || '';
    const isAdmin = !!payload?.groups.includes('immich_admin');

    if (!user) {
      Logger.log(`User with email ${email} does not exist, signing up`, "OAUTH2");

      return await this.immichAuthService.createUser(email, false, null, firstName, lastName, isAdmin);
    }

    let validatedUser = await this.userRepository.findOne({ where: { email: email }});

    if (!validatedUser) {
        throw new InternalServerErrorException();
    }

    if (validatedUser.isAdmin !== isAdmin ||
        validatedUser.firstName !== firstName ||
        validatedUser.lastName !== lastName) {

        Logger.log(`User with email ${email} has changed, updating`, "OAUTH2");

        validatedUser.firstName = firstName;
        validatedUser.lastName = lastName;
        validatedUser.isAdmin = isAdmin;

        validatedUser = await this.userRepository.save(validatedUser);
    }

    Logger.verbose(`Validated user with email ${email}`, "OAUTH2");
    return validatedUser;
  }

}
