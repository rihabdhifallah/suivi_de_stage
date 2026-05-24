import { Body, Controller, Get, Param, Post } from "@nestjs/common";
import { InvitationService } from "./invitation.service";

@Controller("invitations")
export class InvitationController {
  constructor(private service: InvitationService) {}

  @Post("invite")
  invite(@Body() body: any) {
    return this.service.invite(body.encadrantId, body.offreId);
  }

  @Get("offre/:id")
  getByOffre(@Param("id") id: number) {
    return this.service.findByOffre(Number(id));
  }

  @Get("encadrant/:id")
  getByEncadrant(@Param("id") id: number) {
    return this.service.findByEncadrant(Number(id));
  }
}