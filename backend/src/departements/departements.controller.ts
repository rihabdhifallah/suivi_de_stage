import { Controller, Get, Post, Patch, Delete, Body, Param, ParseIntPipe } from '@nestjs/common';
import { DepartementsService } from './departements.service';

@Controller('departements')
export class DepartementsController {
  constructor(private readonly service: DepartementsService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Post()
  create(@Body() body: { nom: string; description?: string }) {
    return this.service.create(body.nom, body.description);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { nom: string; description?: string },
  ) {
    return this.service.update(id, body.nom, body.description);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
