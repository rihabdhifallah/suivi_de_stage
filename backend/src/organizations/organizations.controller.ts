import { Controller, Get, Query } from '@nestjs/common';
import { OrganizationsService } from './organizations.service';

@Controller('organizations')
export class OrganizationsController {
  constructor(private readonly orgService: OrganizationsService) {}

  @Get('search')
  search(@Query('q') q: string) {
    return this.orgService.search(q);
  }

  @Get()
  findAll() {
    return this.orgService.findAll();
  }
}