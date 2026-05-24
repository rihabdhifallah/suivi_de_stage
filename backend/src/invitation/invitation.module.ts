import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";

import { Invitation } from "./invitation.entity";
import { InvitationService } from "./invitation.service";
import { InvitationController } from "./invitation.controller";

import { EncadrantProfessionnel } from "../EncadrantExterne/encadrantprofentity";
import { Offre } from "../offre/offre.entity";

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Invitation,
      EncadrantProfessionnel,
      Offre,
    ]),
  ],
  controllers: [InvitationController],
  providers: [InvitationService],
})
export class InvitationModule {}