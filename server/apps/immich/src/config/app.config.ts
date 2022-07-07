import { ConfigModuleOptions } from '@nestjs/config';
import Joi from 'joi';

export const immichAppConfig: ConfigModuleOptions = {
  envFilePath: '.env',
  isGlobal: true,
  validationSchema: Joi.object({
    NODE_ENV: Joi.string().required().valid('development', 'production', 'staging').default('development'),
    DB_USERNAME: Joi.string().required(),
    DB_PASSWORD: Joi.string().required(),
    DB_DATABASE_NAME: Joi.string().required(),
    JWT_SECRET: Joi.string().required(),
    OAUTH2_ENABLE: Joi.boolean().optional(),
    LOCAL_USERS_DISABLE: Joi.boolean().when('OAUTH2_ENABLE', {
      is: true,
      then: Joi.optional(),
      otherwise: Joi.optional().valid(false),
    }),
    OAUTH2_ISSUER: Joi.any().when('OAUTH2_ENABLE', {
      is: true,
      then: Joi.string().required().uri({
        scheme: ['https'],
      }),
      otherwise: Joi.optional(),
    }),
    OAUTH2_CLIENT_ID: Joi.any().when('OAUTH2_ENABLE', {
      is: true,
      then: Joi.string().required(),
      otherwise: Joi.optional(),
    }),
    OAUTH2_CERTIFICATE: Joi.any().when('OAUTH2_ENABLE', {
      is: true,
      then: Joi.string().required(),
      otherwise: Joi.optional(),
    }),
    ENABLE_MAPBOX: Joi.boolean().required().valid(true, false),
    MAPBOX_KEY: Joi.any().when('ENABLE_MAPBOX', {
      is: false,
      then: Joi.string().optional().allow(null, ''),
      otherwise: Joi.string().required(),
    }),
    VITE_SERVER_ENDPOINT: Joi.string().required(),
  }),
};
