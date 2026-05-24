import { Body, Controller, Get, Param, Post, Delete, Patch, Request, UseGuards } from "@nestjs/common";
import { OffreService } from "./offre.service";
import { AuthGuard } from "@nestjs/passport";

@Controller("offres")
export class OffreController {
  constructor(private readonly service: OffreService) {}

  //  ADMIN
 @Get("admin/all")
findAllForAdmin() {
  return this.service.findAllForAdmin();
}

  //  STUDENT
  @Get("student")
findForStudents() {
  return this.service.findAll(); }

  // ENCADRANT PRO — ses invitations avec détails offre
  @UseGuards(AuthGuard('jwt'))
  @Get("invitations/me")
  getMyInvitations(@Request() req: any) {
    return this.service.findInvitationsForEncadrant(req.user.email);
  }

  //  COMPANY
  @Get("company/:email")
  getByCompany(@Param("email") email: string) {
    return this.service.findByCompany(email);
  }

  //  CREATE
  @Post()
  create(@Body() body: any) {
    return this.service.create(body);
  }

  //  UPDATE
  @Patch(":id")
  update(@Param("id") id: number, @Body() body: any) {
    return this.service.update(id, body);
  }
  @Get(":id")
getOne(@Param("id") id: number) {
  return this.service.findOne(Number(id));
}

  @Patch(":id/status")
  updateStatus(
    @Param("id") id: number,
    @Body("active") active: boolean,
  ) {
    return this.service.updateStatus(id, active);
  }

  @Delete(":id")
  remove(@Param("id") id: number) {
    return this.service.delete(id);
  }
}