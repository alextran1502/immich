import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
  StreamableFile,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Not, Repository } from 'typeorm';
import { AuthUserDto } from '../../decorators/auth-user.decorator';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UserEntity } from '@app/database/entities/user.entity';
import * as bcrypt from 'bcrypt';
import { createReadStream } from 'fs';
import { Response as Res } from 'express';
import {ConfigService} from "@nestjs/config";
import { mapUser, UserResponseDto } from './response-dto/user-response.dto';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(UserEntity)
    private userRepository: Repository<UserEntity>,
    private configService: ConfigService,
  ) {}

  async getAllUsers(authUser: AuthUserDto, isAll: boolean) {
    if (isAll) {
      return await this.userRepository.find();
    }

    return await this.userRepository.find({
      where: { id: Not(authUser.id) },
      order: {
        createdAt: 'DESC',
      },
    });
  }

  async getUserInfo(authUser: AuthUserDto) {
    return this.userRepository.findOne({ where: { id: authUser.id } });
  }

  async getUserCount(isAdmin: boolean) {
    let users;

    if (isAdmin) {
      users = await this.userRepository.find({ where: { isAdmin: true } });
    } else {
      users = await this.userRepository.find();
    }

    return {
      userCount: users.length,
    };
  }

  async createUser(createUserDto: CreateUserDto): Promise<UserResponseDto> {
    if (this.configService.get<boolean>('LOCAL_USERS_DISABLE') === true) {
      throw new BadRequestException("Local users not allowed!");
    }

    const user = await this.userRepository.findOne({ where: { email: createUserDto.email } });

    if (user) {
      throw new BadRequestException('User exists');
    }

    const newUser = new UserEntity();
    newUser.email = createUserDto.email;
    newUser.salt = await bcrypt.genSalt();
    newUser.password = await this.hashPassword(createUserDto.password, newUser.salt);
    newUser.firstName = createUserDto.firstName;
    newUser.lastName = createUserDto.lastName;
    newUser.isAdmin = false;

    try {
      const savedUser = await this.userRepository.save(newUser);

      return mapUser(savedUser);
    } catch (e) {
      Logger.error(e, 'Create new user');
      throw new InternalServerErrorException('Failed to register new user');
    }
  }

  private async hashPassword(password: string, salt: string): Promise<string> {
    return bcrypt.hash(password, salt);
  }

  async updateUser(updateUserDto: UpdateUserDto) {
    const user = await this.userRepository.findOne({ where: { id: updateUserDto.id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    user.lastName = updateUserDto.lastName || user.lastName;
    user.firstName = updateUserDto.firstName || user.firstName;
    user.profileImagePath = updateUserDto.profileImagePath || user.profileImagePath;
    user.shouldChangePassword =
      updateUserDto.shouldChangePassword != undefined ? updateUserDto.shouldChangePassword : user.shouldChangePassword;

    // If payload includes password - Create new password for user
    if (updateUserDto.password) {
      user.salt = await bcrypt.genSalt();
      user.password = await this.hashPassword(updateUserDto.password, user.salt);
    }

    if (updateUserDto.isAdmin) {
      const adminUser = await this.userRepository.findOne({ where: { isAdmin: true } });

      if (adminUser) {
        throw new BadRequestException('Admin user exists');
      }

      user.isAdmin = true;
    }

    try {
      const updatedUser = await this.userRepository.save(user);

      // TODO: this should probably retrun UserResponseDto
      return {
        id: updatedUser.id,
        email: updatedUser.email,
        firstName: updatedUser.firstName,
        lastName: updatedUser.lastName,
        isAdmin: updatedUser.isAdmin,
        profileImagePath: updatedUser.profileImagePath,
      };
    } catch (e) {
      Logger.error(e, 'Create new user');
      throw new InternalServerErrorException('Failed to register new user');
    }
  }

  async createProfileImage(authUser: AuthUserDto, fileInfo: Express.Multer.File) {
    try {
      await this.userRepository.update(authUser.id, {
        profileImagePath: fileInfo.path,
      });

      return {
        userId: authUser.id,
        profileImagePath: fileInfo.path,
      };
    } catch (e) {
      Logger.error(e, 'Create User Profile Image');
      throw new InternalServerErrorException('Failed to create new user profile image');
    }
  }

  async getUserProfileImage(userId: string, res: Res) {
    try {
      const user = await this.userRepository.findOne({ where: { id: userId } });
      if (!user) {
        throw new NotFoundException('User not found');
      }

      if (!user.profileImagePath) {
        res.status(404).send('User does not have a profile image');
        return;
      }

      res.set({
        'Content-Type': 'image/jpeg',
      });
      const fileStream = createReadStream(user.profileImagePath);
      return new StreamableFile(fileStream);
    } catch (e) {
      res.status(404).send('User does not have a profile image');
    }
  }
}
