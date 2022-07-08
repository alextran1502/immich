import { BullModule } from '@nestjs/bull';
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DatabaseModule } from '@app/database';
import { AssetEntity } from '@app/database/entities/asset.entity';
import { ExifEntity } from '@app/database/entities/exif.entity';
import { SmartInfoEntity } from '@app/database/entities/smart-info.entity';
import { UserEntity } from '@app/database/entities/user.entity';
import { MicroservicesService } from './microservices.service';
import { AssetUploadedProcessor } from './processors/asset-uploaded.processor';
import { ThumbnailGeneratorProcessor } from './processors/thumbnail.processor';
import { MetadataExtractionProcessor } from './processors/metadata-extraction.processor';
import { VideoTranscodeProcessor } from './processors/video-transcode.processor';
import { CommunicationModule } from '../../immich/src/api-v1/communication/communication.module';
import {
  assetUploadedQueueName,
  metadataExtractionQueueName,
  thumbnailGeneratorQueueName,
  videoConversionQueueName,
} from '@app/job/constants/queue-name.constant';
import { SystemConfigEntity } from '@app/database/entities/system-config.entity';

@Module({
  imports: [
    DatabaseModule,
    TypeOrmModule.forFeature([UserEntity, ExifEntity, AssetEntity, SmartInfoEntity, SystemConfigEntity]),
    BullModule.forRootAsync({
      useFactory: async () => ({
        redis: {
          host: process.env.REDIS_HOSTNAME || 'immich_redis',
          port: 6379,
        },
      }),
    }),
    BullModule.registerQueue({
      name: thumbnailGeneratorQueueName,
      defaultJobOptions: {
        attempts: 3,
        removeOnComplete: true,
        removeOnFail: false,
      },
    }),
    BullModule.registerQueue({
      name: assetUploadedQueueName,
      defaultJobOptions: {
        attempts: 3,
        removeOnComplete: true,
        removeOnFail: false,
      },
    }),
    BullModule.registerQueue({
      name: metadataExtractionQueueName,
      defaultJobOptions: {
        attempts: 3,
        removeOnComplete: true,
        removeOnFail: false,
      },
    }),
    BullModule.registerQueue({
      name: videoConversionQueueName,
      defaultJobOptions: {
        attempts: 3,
        removeOnComplete: true,
        removeOnFail: false,
      },
    }),
    CommunicationModule,
  ],
  controllers: [],
  providers: [
    MicroservicesService,
    AssetUploadedProcessor,
    ThumbnailGeneratorProcessor,
    MetadataExtractionProcessor,
    VideoTranscodeProcessor,
  ],
  exports: [],
})
export class MicroservicesModule {}
