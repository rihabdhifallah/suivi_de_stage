import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Stage } from './stage.entity';
import { StageService } from './stage.service';
import { StageController } from './stage.controller';
import { Notification } from '../notifications/notification.entity';

@Module({
imports: [
  TypeOrmModule.forFeature([Stage, Notification]),
],  providers: [StageService],
  controllers: [StageController],
  exports: [StageService], 
})
export class StageModule {}