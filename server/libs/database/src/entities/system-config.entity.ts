import { Column, Entity, PrimaryGeneratedColumn, Unique } from 'typeorm';

@Entity('system_config')
@Unique(['key', 'category'])
export class SystemConfigEntity {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  category!: string;

  @Column()
  key!: ConfigKey;

  @Column({ type: 'varchar', nullable: true })
  value!: string | null;
}

export enum ConfigKey {
  FFMPEG_CRF = 'ffmpeg_crf',
  FFMPEG_PRESET = 'ffmpeg_preset',
  FFMPEG_TARGET_VIDEO_CODEC = 'ffmpeg_target_video_codec',
  FFMPEG_TARGET_AUDIO_CODEC = 'ffmpeg_target_audio_codec',
  FFMEG_TARGET_SCALING = 'ffmpeg_target_scaling',
}
