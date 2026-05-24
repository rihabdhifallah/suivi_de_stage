import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ReunionsService } from './reunions.service';

@Controller('reunions')
@UseGuards(AuthGuard('jwt'))
export class ReunionsController {
  constructor(private readonly service: ReunionsService) {}

  @Get()
  async getMyReunions(@Request() req) {
    return this.service.getReunionsForUser(req.user.email, req.user.role);
  }

  @Post()
  async createReunion(@Body() body: any, @Request() req) {
    return this.service.createReunion(body, req.user.email);
  }
}
