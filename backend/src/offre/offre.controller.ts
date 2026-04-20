import { Body, Controller, Get, Param, Post, Delete, Patch } from "@nestjs/common";
import { OffreService } from "./offre.service";

@Controller("offres")
export class OffreController {

  constructor(private readonly service: OffreService) {}

  // CREATE
  @Post()
  create(@Body() body: any) {
    return this.service.create(body);
  }

  // GET BY EMAIL
  @Get(":email")
  getByCompany(@Param("email") email: string) {
    return this.service.findByCompany(email);
  }

  // DELETE (optionnel)
  @Delete(":id")
  remove(@Param("id") id: number) {
    return this.service.delete(id);
  }
 @Patch(':id')
update(@Param('id') id: number, @Body() body: any) {
  return this.service.update(id, body);
}

@Patch(':id/status')
updateStatus(
  @Param('id') id: number,
  @Body('active') active: boolean
) {
  return this.service.updateStatus(id, active);
}
}