import {
  Controller,
  Post,
  Get,
  Delete,
  Patch,
  Param,
  Body,
  Req,
} from '@nestjs/common';

import { StageService } from './stage.service';
import { StageStatus } from './stage-status.enum';

@Controller('stages')
export class StageController {
  constructor(private readonly stageService: StageService) {}

  // ================= CREATE =================

  @Post('company')
  createCompany(@Body() body: any) {
    return this.stageService.createCompanyStage(body);
  }

  @Post('student')
  propose(@Body() body: any) {
    return this.stageService.createStudentProposal(body);
  }

  @Post('admin')
  createAdmin(@Body() body: any) {
    return this.stageService.createAdminStage(body);
  }

  // ================= GET =================

  @Get()
  findAll() {
    return this.stageService.findAll();
  }

  @Get('company/:name')
  getByCompany(@Param('name') name: string) {
    return this.stageService.findByCompany(name);
  }

  @Get('notifications/:company')
  getNotifications(@Param('company') company: string) {
    return this.stageService.getNotifications(company);
  }

  // ================= UPDATE =================

  @Patch(':id')
  update(@Param('id') id: string, @Body() body: any) {
    return this.stageService.updateStage(Number(id), body);
  }

  // ================= DELETE =================

  @Delete(':id')
  delete(@Param('id') id: string) {
    return this.stageService.deleteStage(Number(id));
  }

  // ================= ADMIN FIX =================

  @Get('admin/all-stages')
  adminStages() {
    return this.stageService.findAll();
  }

  @Patch('accept/:id')
accept(@Param('id') id: string) {
  return this.stageService.updateStatus(Number(id), StageStatus.ACCEPTED);
}

@Patch('reject/:id')
reject(@Param('id') id: string) {
  return this.stageService.updateStatus(Number(id), StageStatus.REJECTED);
}

@Patch('publish/:id')
publish(@Param('id') id: string) {
  return this.stageService.updateStatus(Number(id), StageStatus.PUBLISHED);
}

@Get('company/me')
getMyStages(@Req() req) {
  return this.stageService.findByCompany(req.user.name);
}
@Post('propose')
create(@Body() data: any) {
  return this.stageService.createCompanyStage(data);
}
}