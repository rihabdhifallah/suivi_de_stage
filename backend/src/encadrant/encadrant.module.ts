import { Module } from '@nestjs/common';
import { EncadrantController } from './encadrant.controller';
import { EncadrantService } from './encadrant.service';

@Module({
  controllers: [EncadrantController],
  providers: [EncadrantService],
})
export class EncadrantModule {}