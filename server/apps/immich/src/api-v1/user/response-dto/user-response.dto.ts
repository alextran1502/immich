import { UserEntity } from '@app/database/entities/user.entity';

export interface UserResponseDto {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  createdAt: string;
  isAdmin: boolean;
  profileImagePath: string;
  isFirstLogin: boolean;
}

export function mapUser(entity: UserEntity): UserResponseDto {
  return {
    id: entity.id,
    email: entity.email,
    firstName: entity.firstName,
    lastName: entity.lastName,
    createdAt: entity.createdAt,
    isAdmin: entity.isAdmin,
    profileImagePath: entity.profileImagePath,
    isFirstLogin: entity.shouldChangePassword,
  };
}
