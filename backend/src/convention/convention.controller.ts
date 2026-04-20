import { Controller, Post, Get, Patch, Body, Param } from '@nestjs/common';
import { ConventionService } from './convention.service';

@Controller('conventions')
export class ConventionController {
  constructor(private service: ConventionService) {}

  @Post()
  create(@Body() body: any) {
    return this.service.create(body);
  }

  @Patch(':id')
  update(@Param('id') id: number, @Body() body: any) {
    return this.service.updateStatus(id, body.status);
  }

 @Get()
findAll() {
  return this.service.findAll(); // 
}
  @Get('student')
  findForStudent() {
    return this.service.findAccepted(); // STUDENT
  }
  @Get('accepted')
findAccepted() {
  return this.service.findAccepted();
}
}
