import { PostgresConnectionOptions } from 'typeorm/driver/postgres/PostgresConnectionOptions';
import { DataSource } from 'typeorm';

export const databaseConfig: PostgresConnectionOptions = {
  type: 'postgres',
  host: process.env.DB_HOSTNAME || 'immich_postgres',
  port: 5432,
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_DATABASE_NAME || 'immich',
  entities: [__dirname + '/../**/*.entity.{js,ts}'],
  synchronize: false,
  migrations: [__dirname + '/../migrations/*.{js,ts}'],
  migrationsRun: true,
};

export const dataSource = new DataSource(databaseConfig);
