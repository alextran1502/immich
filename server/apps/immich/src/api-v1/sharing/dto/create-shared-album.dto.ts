import { IsNotEmpty, IsOptional } from 'class-validator';
import { AssetEntity } from '@app/database/entities/asset.entity';

export class CreateSharedAlbumDto {
  @IsNotEmpty()
  albumName: string;

  @IsNotEmpty()
  sharedWithUserIds: string[];

  @IsOptional()
  assetIds: string[];
}
