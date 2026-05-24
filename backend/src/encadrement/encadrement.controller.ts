import {
  Controller,
  Get,
  Post,
  Body,
  Delete,
  Param,
  UseGuards,
  Request,
  ParseIntPipe,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

import { EncadrementService } from './encadrement.service';
import { CreateEncadrementDto } from './dto/create-encadrement.dto';

@Controller('encadrements')
@UseGuards(AuthGuard('jwt'))
export class EncadrementController {
  constructor(private readonly service: EncadrementService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get('my')
  getMyStudent(@Request() req) {
    return this.service.findByStudent(req.user.email);
  }

  @Get('encadrant/my')
  getMyEncadrant(@Request() req) {
    return this.service.findByEncadrant(req.user.email);
  }

 @Post()
create(@Body() body) {
  return this.service.create(body);
}

 @Post(':id/send')
send(@Param('id', ParseIntPipe) id: number) {
  return this.service.sendMessage(id);
}

@Delete(':id')
delete(@Param('id', ParseIntPipe) id: number) {
  return this.service.remove(id);
}
}