import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Presentation } from './presentation.entity';
import { User } from '../users/user.entity';
import { PresentationsService } from './presentations.service';
import { PresentationsController } from './presentations.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Presentation, User]),
  ],
  controllers: [PresentationsController],
  providers: [PresentationsService],
})
export class PresentationsModule {}