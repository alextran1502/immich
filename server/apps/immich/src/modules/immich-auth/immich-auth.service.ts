import {BadRequestException, Injectable, InternalServerErrorException, Logger} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import {UserEntity} from "@app/database/entities/user.entity";
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import * as crypto from "crypto";

type WsToken = {
  token: string;
  expiry: number;
};

const WS_TOKEN_VALIDITY = 30; // in seconds

@Injectable()
export class ImmichAuthService {

  constructor(
    @InjectRepository(UserEntity)
    private userRepository: Repository<UserEntity>,
  ) {};

  // maps a userId to a valid WS token
  private wsTokenMap = new Map<string, WsToken>();

  async generateWsToken(userId: string): Promise<string> {
    Logger.verbose(`Generating WS token for ${userId}`, "ImmichWSAuth");
    const newWsToken: WsToken = {
      token: crypto.randomBytes(64).toString('hex'),
      expiry: Date.now() + WS_TOKEN_VALIDITY * 1000,
    };

    this.wsTokenMap.set(userId, newWsToken);

    return newWsToken.token;
  };

  async validateWsToken(token: string): Promise<UserEntity | undefined> {
    for (const [userId, wsToken] of this.wsTokenMap) {
      if (Date.now() > wsToken.expiry) {
        this.wsTokenMap.delete(userId);
      } else {
        if (token === wsToken.token) {
          const user = this.userRepository.findOneOrFail( { where: {id: userId}});
          this.wsTokenMap.delete(userId);
          Logger.verbose(`Validated WS token for ${userId}`, "ImmichWSAuth");
          return user;
        }
      }
    }
    return undefined;
  }

  async createUser(email: string, localUser: boolean, password: string | null, firstName = "", lastName = "", isAdmin = false) {
    const registerUser = await this.userRepository.findOne({ where: { email: email }});

    if (registerUser) {
      throw new BadRequestException('User already exists');
    }

    const newUser = new UserEntity();
    newUser.email = email;
    newUser.firstName = firstName;
    newUser.lastName = lastName;
    newUser.isAdmin = isAdmin;
    if (localUser) {
      if (password === null) {
        throw new InternalServerErrorException();
      }
      newUser.salt = await bcrypt.genSalt();
      newUser.password = await ImmichAuthService.hashPassword(password, newUser.salt);
      newUser.isLocalUser = true;
    } else {
      newUser.isLocalUser = false;
    }

    return await this.userRepository.save(newUser);
  }

  async createAdmin(email: string, localUser: boolean, password: string | null, firstName = "", lastName = "") {
    const adminUser = await this.userRepository.findOne({ where: { isAdmin: true } });

    if (adminUser) {
      throw new BadRequestException('Admin user already exists');
    }

    return await this.createUser(email, localUser, password, firstName, lastName, true);
  }

  private static async hashPassword(password: string, salt: string): Promise<string> {
    return bcrypt.hash(password, salt);
  }

  public static getEnabledStrategies() {
    // sadly it's not possible to use ConfigService in a static context :(
    if (process.env.OAUTH2_ENABLE === 'true') {
      if (process.env.LOCAL_USERS_DISABLE === 'true') {
        return ['oauth2'];
      } else {
        return ['jwt', 'oauth2'];
      }
    } else {
      return ['jwt'];
    }
  }



}