import { Body, Controller, Get, Post } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  findAll() {
    return this.usersService.findAll();
  }

  @Get('companies')
  findCompanies() {
    return this.usersService.findCompanies();
  }

  @Post()
  create(@Body() dto: any) {
    return this.usersService.create(dto);
  }
  @Get("academic")
  findAcademic(){
    return this.usersService.findAcademic();
  }
}
