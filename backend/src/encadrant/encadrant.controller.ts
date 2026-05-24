import { Controller, Get } from '@nestjs/common';
import { EncadrantService } from './encadrant.service';

@Controller('encadrant')
export class EncadrantController {
  constructor(private readonly service: EncadrantService) {}

  @Get('stats')
  getStats() {
    return this.service.getStats();
  }
}