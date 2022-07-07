import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { UserEntity } from '@app/database/entities/user.entity';

export class AuthUserDto {
  id!: string;
  email!: string;
}

export const GetAuthUser = createParamDecorator((data, ctx: ExecutionContext): AuthUserDto => {
  const req = ctx.switchToHttp().getRequest<{ user: UserEntity }>();

  const { id, email } = req.user;

  return {
    id: id.toString(),
    email,
  };
});
