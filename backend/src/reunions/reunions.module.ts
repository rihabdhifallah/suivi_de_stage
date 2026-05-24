import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Reunion } from './reunion.entity';
import { User } from '../users/user.entity';
import { ReunionsController } from './reunions.controller';
import { ReunionsService } from './reunions.service';
import { NotificationModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Reunion, User]),
    NotificationModule,
  ],
  controllers: [ReunionsController],
  providers: [ReunionsService],
  exports: [ReunionsService],
})
export class ReunionsModule {}
