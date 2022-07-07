import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users')
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ default: '' })
  firstName!: string;

  @Column({ default: '' })
  lastName!: string;

  @Column({ default: false })
  isAdmin!: boolean;

  @Column()
  email!: string;

  @Column({ select: false })
  password?: string;

  @Column({ select: false })
  salt?: string;

  @Column({ default: '' })
  profileImagePath!: string;

  @Column({ default: true })
  shouldChangePassword!: boolean;

  @CreateDateColumn()
  createdAt!: string;

  @Column({default: true})
  isLocalUser!: boolean;
}
