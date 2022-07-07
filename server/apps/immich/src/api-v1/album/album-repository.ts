import { AlbumEntity } from '@app/database/entities/album.entity';
import { AssetAlbumEntity } from '@app/database/entities/asset-album.entity';
import { UserAlbumEntity } from '@app/database/entities/user-album.entity';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, SelectQueryBuilder, DataSource } from 'typeorm';
import { AddAssetsDto } from './dto/add-assets.dto';
import { AddUsersDto } from './dto/add-users.dto';
import { CreateAlbumDto } from './dto/create-album.dto';
import { GetAlbumsDto } from './dto/get-albums.dto';
import { RemoveAssetsDto } from './dto/remove-assets.dto';
import { UpdateAlbumDto } from './dto/update-album.dto';

export interface IAlbumRepository {
  create(ownerId: string, createAlbumDto: CreateAlbumDto): Promise<AlbumEntity>;
  getList(ownerId: string, getAlbumsDto: GetAlbumsDto): Promise<AlbumEntity[]>;
  get(albumId: string): Promise<AlbumEntity | undefined>;
  delete(album: AlbumEntity): Promise<void>;
  addSharedUsers(album: AlbumEntity, addUsersDto: AddUsersDto): Promise<AlbumEntity>;
  removeUser(album: AlbumEntity, userId: string): Promise<void>;
  removeAssets(album: AlbumEntity, removeAssets: RemoveAssetsDto): Promise<boolean>;
  addAssets(album: AlbumEntity, addAssetsDto: AddAssetsDto): Promise<AlbumEntity>;
  updateAlbum(album: AlbumEntity, updateAlbumDto: UpdateAlbumDto): Promise<AlbumEntity>;
}

export const ALBUM_REPOSITORY = 'ALBUM_REPOSITORY';

@Injectable()
export class AlbumRepository implements IAlbumRepository {
  constructor(
    @InjectRepository(AlbumEntity)
    private albumRepository: Repository<AlbumEntity>,

    @InjectRepository(AssetAlbumEntity)
    private assetAlbumRepository: Repository<AssetAlbumEntity>,

    @InjectRepository(UserAlbumEntity)
    private userAlbumRepository: Repository<UserAlbumEntity>,

    private dataSource: DataSource,
  ) {}

  async create(ownerId: string, createAlbumDto: CreateAlbumDto): Promise<AlbumEntity> {
    return this.dataSource.transaction(async (transactionalEntityManager) => {
      // Create album entity
      const newAlbum = new AlbumEntity();
      newAlbum.ownerId = ownerId;
      newAlbum.albumName = createAlbumDto.albumName;

      const album = await transactionalEntityManager.save(newAlbum);

      // Add shared users
      if (createAlbumDto.sharedWithUserIds?.length) {
        for (const sharedUserId of createAlbumDto.sharedWithUserIds) {
          const newSharedUser = new UserAlbumEntity();
          newSharedUser.albumId = album.id;
          newSharedUser.sharedUserId = sharedUserId;

          await transactionalEntityManager.save(newSharedUser);
        }
      }

      // Add shared assets
      const newRecords: AssetAlbumEntity[] = [];

      if (createAlbumDto.assetIds?.length) {
        for (const assetId of createAlbumDto.assetIds) {
          const newAssetAlbum = new AssetAlbumEntity();
          newAssetAlbum.assetId = assetId;
          newAssetAlbum.albumId = album.id;

          newRecords.push(newAssetAlbum);
        }
      }

      if (!album.albumThumbnailAssetId && newRecords.length > 0) {
        album.albumThumbnailAssetId = newRecords[0].assetId;
        await transactionalEntityManager.save(album);
      }

      await transactionalEntityManager.save([...newRecords]);

      return album;
    });
  }

  getList(ownerId: string, getAlbumsDto: GetAlbumsDto): Promise<AlbumEntity[]> {
    const filteringByShared = typeof getAlbumsDto.shared == 'boolean';
    const userId = ownerId;
    let query = this.albumRepository.createQueryBuilder('album');

    const getSharedAlbumIdsSubQuery = (qb: SelectQueryBuilder<AlbumEntity>) => {
      return qb
        .subQuery()
        .select('albumSub.id')
        .from(AlbumEntity, 'albumSub')
        .innerJoin('albumSub.sharedUsers', 'userAlbumSub')
        .where('albumSub.ownerId = :ownerId', { ownerId: userId })
        .getQuery();
    };

    if (filteringByShared) {
      if (getAlbumsDto.shared) {
        // shared albums
        query = query
          .innerJoinAndSelect('album.sharedUsers', 'sharedUser')
          .innerJoinAndSelect('sharedUser.userInfo', 'userInfo')
          .where((qb) => {
            // owned and shared with other users
            const subQuery = getSharedAlbumIdsSubQuery(qb);
            return `album.id IN ${subQuery}`;
          })
          .orWhere((qb) => {
            // shared with userId
            const subQuery = qb
              .subQuery()
              .select('userAlbum.albumId')
              .from(UserAlbumEntity, 'userAlbum')
              .where('userAlbum.sharedUserId = :sharedUserId', { sharedUserId: userId })
              .getQuery();
            return `album.id IN ${subQuery}`;
          });
      } else {
        // owned, not shared albums
        query = query.where('album.ownerId = :ownerId', { ownerId: userId }).andWhere((qb) => {
          const subQuery = getSharedAlbumIdsSubQuery(qb);
          return `album.id NOT IN ${subQuery}`;
        });
      }
    } else {
      // owned and shared with userId
      query = query
        .leftJoinAndSelect('album.sharedUsers', 'sharedUser')
        .leftJoinAndSelect('sharedUser.userInfo', 'userInfo')
        .where('album.ownerId = :ownerId', { ownerId: userId })
        .orWhere((qb) => {
          const subQuery = qb
            .subQuery()
            .select('userAlbum.albumId')
            .from(UserAlbumEntity, 'userAlbum')
            .where('userAlbum.sharedUserId = :sharedUserId', { sharedUserId: userId })
            .getQuery();
          return `album.id IN ${subQuery}`;
        });
    }
    return query.orderBy('album.createdAt', 'DESC').getMany();
  }

  async get(albumId: string): Promise<AlbumEntity | undefined> {
    const album = await this.albumRepository.findOne({
      where: { id: albumId },
      relations: ['sharedUsers', 'sharedUsers.userInfo', 'assets', 'assets.assetInfo'],
    });

    if (!album) {
      return;
    }
    // TODO: sort in query
    const sortedSharedAsset = album.assets?.sort(
      (a, b) => new Date(a.assetInfo.createdAt).valueOf() - new Date(b.assetInfo.createdAt).valueOf(),
    );

    album.assets = sortedSharedAsset;

    return album;
  }

  async delete(album: AlbumEntity): Promise<void> {
    await this.albumRepository.delete({ id: album.id, ownerId: album.ownerId });
  }

  async addSharedUsers(album: AlbumEntity, addUsersDto: AddUsersDto): Promise<AlbumEntity> {
    const newRecords: UserAlbumEntity[] = [];

    for (const sharedUserId of addUsersDto.sharedUserIds) {
      const newEntity = new UserAlbumEntity();
      newEntity.albumId = album.id;
      newEntity.sharedUserId = sharedUserId;

      newRecords.push(newEntity);
    }

    await this.userAlbumRepository.save([...newRecords]);
    return this.get(album.id) as Promise<AlbumEntity>; // There is an album for sure
  }

  async removeUser(album: AlbumEntity, userId: string): Promise<void> {
    await this.userAlbumRepository.delete({ albumId: album.id, sharedUserId: userId });
  }

  async removeAssets(album: AlbumEntity, removeAssetsDto: RemoveAssetsDto): Promise<boolean> {
    let deleteAssetCount = 0;
    // TODO: should probably do a single delete query?
    for (const assetId of removeAssetsDto.assetIds) {
      const res = await this.assetAlbumRepository.delete({ albumId: album.id, assetId: assetId });
      if (res.affected == 1) {
        deleteAssetCount++;
      }
    }

    // TODO: No need to return boolean if using a singe delete query
    return deleteAssetCount == removeAssetsDto.assetIds.length;
  }

  async addAssets(album: AlbumEntity, addAssetsDto: AddAssetsDto): Promise<AlbumEntity> {
    const newRecords: AssetAlbumEntity[] = [];

    for (const assetId of addAssetsDto.assetIds) {
      const newAssetAlbum = new AssetAlbumEntity();
      newAssetAlbum.assetId = assetId;
      newAssetAlbum.albumId = album.id;

      newRecords.push(newAssetAlbum);
    }

    // Add album thumbnail if not exist.
    if (!album.albumThumbnailAssetId && newRecords.length > 0) {
      album.albumThumbnailAssetId = newRecords[0].assetId;
      await this.albumRepository.save(album);
    }

    await this.assetAlbumRepository.save([...newRecords]);
    return this.get(album.id) as Promise<AlbumEntity>; // There is an album for sure
  }

  updateAlbum(album: AlbumEntity, updateAlbumDto: UpdateAlbumDto): Promise<AlbumEntity> {
    album.albumName = updateAlbumDto.albumName;

    return this.albumRepository.save(album);
  }
}
