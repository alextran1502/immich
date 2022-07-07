import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import request from 'supertest';
import { clearDb, getAuthUser, authCustom } from './test-utils';
import { databaseConfig } from '@app/database/config/database.config';
import { AlbumModule } from '../src/api-v1/album/album.module';
import { CreateAlbumDto } from '../src/api-v1/album/dto/create-album.dto';
import { AuthUserDto } from '../src/decorators/auth-user.decorator';
import { UserService } from '../src/api-v1/user/user.service';
import { UserModule } from '../src/api-v1/user/user.module';
import {ImmichAuthModule} from "../src/modules/immich-auth/immich-auth.module";

function _createAlbum(app: INestApplication, data: CreateAlbumDto) {
  return request(app.getHttpServer()).post('/album').send(data);
}

describe('Album', () => {
  let app: INestApplication;

  afterAll(async () => {
    await clearDb();
    await app.close();
  });

  describe('without auth', () => {
    beforeAll(async () => {
      const moduleFixture: TestingModule = await Test.createTestingModule({
        imports: [AlbumModule, ImmichAuthModule, TypeOrmModule.forRoot(databaseConfig)],
      }).compile();

      app = moduleFixture.createNestApplication();
      await app.init();
    });

    afterAll(async () => {
      await app.close();
    });

    it('prevents fetching albums if not auth', async () => {
      const { status } = await request(app.getHttpServer()).get('/album');
      expect(status).toEqual(401);
    });
  });

  describe('with auth', () => {
    let authUser: AuthUserDto;
    let userService: UserService;

    beforeAll(async () => {
      const builder = Test.createTestingModule({
        imports: [AlbumModule, UserModule, TypeOrmModule.forRoot(databaseConfig)],
      });
      authUser = getAuthUser(); // set default auth user
      const moduleFixture: TestingModule = await authCustom(builder, () => authUser).compile();

      app = moduleFixture.createNestApplication();
      userService = app.get(UserService);
      await app.init();
    });

    describe('with empty DB', () => {
      afterEach(async () => {
        await clearDb();
      });

      it('creates an album', async () => {
        const data: CreateAlbumDto = {
          albumName: 'first albbum',
        };
        const { status, body } = await _createAlbum(app, data);
        expect(status).toEqual(201);
        expect(body).toEqual(
          expect.objectContaining({
            ownerId: authUser.id,
            albumName: data.albumName,
          }),
        );
      });
    });

    describe('with albums in DB', () => {
      const userOneShared = 'userOneShared';
      const userOneNotShared = 'userOneNotShared';
      const userTwoShared = 'userTwoShared';
      const userTwoNotShared = 'userTwoNotShared';
      let userOne: AuthUserDto;
      let userTwo: AuthUserDto;

      beforeAll(async () => {
        // setup users
        const result = await Promise.all([
          userService.createUser({
            email: 'one@test.com',
            password: '1234',
            firstName: 'one',
            lastName: 'test',
          }),
          userService.createUser({
            email: 'two@test.com',
            password: '1234',
            firstName: 'two',
            lastName: 'test',
          }),
        ]);
        userOne = result[0];
        userTwo = result[1];
        // add user one albums
        authUser = userOne;
        await Promise.all([
          _createAlbum(app, { albumName: userOneShared, sharedWithUserIds: [userTwo.id] }),
          _createAlbum(app, { albumName: userOneNotShared }),
        ]);
        // add user two albums
        authUser = userTwo;
        await Promise.all([
          _createAlbum(app, { albumName: userTwoShared, sharedWithUserIds: [userOne.id] }),
          _createAlbum(app, { albumName: userTwoNotShared }),
        ]);
        // set user one as authed for next requests
        authUser = userOne;
      });

      it('returns the album collection including owned and shared', async () => {
        const { status, body } = await request(app.getHttpServer()).get('/album');
        expect(status).toEqual(200);
        expect(body).toHaveLength(3);
        expect(body).toEqual(
          expect.arrayContaining([
            expect.objectContaining({ ownerId: userOne.id, albumName: userOneShared, shared: true }),
            expect.objectContaining({ ownerId: userOne.id, albumName: userOneNotShared, shared: false }),
            expect.objectContaining({ ownerId: userTwo.id, albumName: userTwoShared, shared: true }),
          ]),
        );
      });

      it('returns the album collection filtered by shared', async () => {
        const { status, body } = await request(app.getHttpServer()).get('/album?shared=true');
        expect(status).toEqual(200);
        expect(body).toHaveLength(2);
        expect(body).toEqual(
          expect.arrayContaining([
            expect.objectContaining({ ownerId: userOne.id, albumName: userOneShared, shared: true }),
            expect.objectContaining({ ownerId: userTwo.id, albumName: userTwoShared, shared: true }),
          ]),
        );
      });

      it('returns the album collection filtered by NOT shared', async () => {
        const { status, body } = await request(app.getHttpServer()).get('/album?shared=false');
        expect(status).toEqual(200);
        expect(body).toHaveLength(1);
        expect(body).toEqual(
          expect.arrayContaining([
            expect.objectContaining({ ownerId: userOne.id, albumName: userOneNotShared, shared: false }),
          ]),
        );
      });
    });
  });
});
