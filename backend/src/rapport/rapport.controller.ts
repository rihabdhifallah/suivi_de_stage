import { Controller, Post, Body } from '@nestjs/common';

@Controller('rapport')
export class RapportController {

private rapports: any[] = [];
  @Post()
  create(@Body() body: any) {
    this.rapports.push(body);
    return { message: 'Rapport saved', data: body };
  }
}