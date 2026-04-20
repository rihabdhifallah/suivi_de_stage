import { Module } from '@nestjs/common';
import { ConventionController } from './convention.controller';
import { ConventionService } from './convention.service';

@Module({
  controllers: [ConventionController],
  providers: [ConventionService],
})
export class ConventionModule {}