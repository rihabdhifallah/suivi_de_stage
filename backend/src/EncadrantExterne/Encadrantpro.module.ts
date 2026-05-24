import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Offre } from "../offre/offre.entity";
import { EncadrantService } from "./EncadrantproService";
import { EncadrantProfessionnel } from "./encadrantprofentity";
import { EncadrantController } from "../EncadrantExterne/encadrantpro.controller";
import { User } from "../users/user.entity";
import { MailModule } from "../mail/mail.module";

@Module({
  imports: [
    TypeOrmModule.forFeature([EncadrantProfessionnel, Offre, User]),
    MailModule,
  ],
  controllers: [EncadrantController],
  providers: [EncadrantService],
})
export class EncadrantProfessionnelModule {}