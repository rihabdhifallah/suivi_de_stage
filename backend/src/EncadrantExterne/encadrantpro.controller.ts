import { Body, Controller, Delete, Get, Param, Patch, Post } from "@nestjs/common";
import { EncadrantService } from "../EncadrantExterne/EncadrantproService";

@Controller("encadrants")
export class EncadrantController {
  constructor(private service: EncadrantService) {}

  @Post()
  create(@Body() body: any) {
    return this.service.create(body);
  }

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get("company/:companyId")
  getByCompany(@Param("companyId") companyId: number) {
    return this.service.findByCompany(Number(companyId));
  }

  @Patch(":id")
  update(@Param("id") id: string, @Body() body: any) {
    return this.service.update(Number(id), body);
  }

  @Delete(":id")
  delete(@Param("id") id: string) {
    return this.service.delete(Number(id));
  }
}