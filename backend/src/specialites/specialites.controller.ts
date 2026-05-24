import { Controller, Get, Post, Patch, Delete, Body, Param, ParseIntPipe } from '@nestjs/common';
import { SpecialitesService } from './specialites.service';

@Controller('specialites')
export class SpecialitesController {
  constructor(private readonly service: SpecialitesService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get('by-departement/:id')
  findByDepartement(@Param('id', ParseIntPipe) id: number) {
    return this.service.findByDepartement(id);
  }

  @Post()
  create(@Body() body: { nom: string; description?: string; departementId?: number }) {
    return this.service.create(body.nom, body.description, body.departementId);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { nom: string; description?: string; departementId?: number },
  ) {
    return this.service.update(id, body.nom, body.description, body.departementId);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
