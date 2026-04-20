// notifications.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Notification } from './notification.entity';
import { NotificationsService } from './notifications.service';
import { NotificationController } from './notifications.controller';
import { TaskModule } from 'src/task/task.module';

@Module({
  imports: [TypeOrmModule.forFeature([Notification]),
        TaskModule, // 

],
  providers: [NotificationsService],
  controllers: [NotificationController],
  exports: [NotificationsService],

})
export class NotificationsModule {}