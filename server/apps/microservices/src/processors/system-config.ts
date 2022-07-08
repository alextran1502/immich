import { Repository } from 'typeorm';
import { ConfigKey, SystemConfigEntity } from '@app/database/entities/system-config.entity';

type SystemConfig = {
  ffmpeg: {
    [key in ConfigKey]: string;
  };
};

const configDefaults: SystemConfig = {
  ffmpeg: {
    [ConfigKey.FFMPEG_CRF]: '23',
    [ConfigKey.FFMPEG_PRESET]: 'ultrafast',
    [ConfigKey.FFMPEG_TARGET_VIDEO_CODEC]: 'libx264',
    [ConfigKey.FFMPEG_TARGET_AUDIO_CODEC]: 'mp3',
    [ConfigKey.FFMEG_TARGET_SCALING]: '1280:-2',
  },
};

export class SystemConfigClient {
  constructor(private systemConfigRepository: Repository<SystemConfigEntity>) {}

  getConfig = async (): Promise<SystemConfig> => {
    const config = await this.systemConfigRepository.find();

    return (Object.keys(ConfigKey) as Array<keyof typeof ConfigKey>).reduce((previous, current, key) => {
      const nextConfigItem = { [current]: getConfigValue(ConfigKey[current], config) };
      return { ...previous, ...nextConfigItem };
    }, configDefaults);
  };
}

const getConfigValue = (key: ConfigKey, config: SystemConfigEntity[]) => {
  return (
    config.find((configEntry) => {
      return configEntry.key === key;
    })?.value ?? configDefaults.ffmpeg[key]
  );
};
