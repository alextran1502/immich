import {Injectable} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ImmichAuthService } from '../immich-auth.service';

@Injectable()
export class ImmichAuthGuard extends AuthGuard(ImmichAuthService.getEnabledStrategies()) {}