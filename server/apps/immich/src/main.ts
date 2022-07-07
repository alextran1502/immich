import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { RedisIoAdapter } from './middlewares/redis-io.adapter.middleware';

async function bootstrap() {

  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    logger: process.env.NODE_ENV === 'development' ? ['verbose'] : ['log', 'warn', 'error'],
  });

  app.set('trust proxy');

  if (process.env.NODE_ENV === 'development') {
    app.enableCors();
  }

  app.useWebSocketAdapter(new RedisIoAdapter(app));

  await app.listen(process.env.PORT || 3001, () => {
    if (process.env.NODE_ENV === 'development') {
      Logger.log('Running Immich Server in DEVELOPMENT environment', 'ImmichServer');
    }

    if (process.env.NODE_ENV === 'production') {
      Logger.log('Running Immich Server in PRODUCTION environment', 'ImmichServer');
    }
  });
}
bootstrap();
