import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { StagesService } from './stages.service';
import { StageStatus } from './stage-status.enum';

@Controller('stages')
export class StagesController {
  stageRepo: any;
  constructor(private service: StagesService) {}

  // ================= GET ALL (Student) =================
  @Get()
  findAll() {
    return this.service.findAll();
  }
  

  // ================= CREATE =================
  @Post()
  create(@Body() dto: any) {
    console.log("DTO:", dto);
    return this.service.create(dto);
  }

  // ================= ACCEPT =================
  @Patch('accept/:id')
  accept(@Param('id') id: string) {
    return this.service.updateStatus(Number(id), StageStatus.ACCEPTED);
  }

  // ================= REJECT =================
  @Patch('reject/:id')
  reject(@Param('id') id: string) {
    return this.service.updateStatus(Number(id), StageStatus.REJECTED);
  }

  // ================= COMPANY STAGES =================
  @Get('company/:email')
  findCompany(@Param('email') email: string) {
    return this.service.findCompanyStages(email);
  }

  // ================= ADMIN =================
  @Get('admin')
  getAllStages() {
    return this.service.findAll(); // 
  }
  @Get('published')
findPublished() {
  return this.service.findAll();
}
@Get('student/stages')
getForStudents() {
  return this.service.findForStudents();
}
@Get('student/stages')
findForStudent() {
  return this.stageRepo.find({
    where: {
      published: true,
      active: true,
    },
  });
}
}