import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Application } from "./application.entity";
import { ApplicationService } from "./application.service";
import { ApplicationController } from "./application.controller";
import { PassportModule } from "@nestjs/passport";
import { JwtModule } from "@nestjs/jwt";
import { JwtStrategy } from "src/auth/jwt.strategy";
import { Stage } from "src/stages/stage.entity";
import { Notification } from "../notifications/notification.entity";
import { User } from "../users/user.entity";
import { EncadrantProfessionnel } from "../EncadrantExterne/encadrantprofentity";

@Module({
imports: [
    TypeOrmModule.forFeature([Application, Stage, Notification, User, EncadrantProfessionnel]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({
      secret: 'SECRET_KEY',
    }),
  ],  controllers: [ApplicationController],
  providers: [ApplicationService, JwtStrategy],
})
export class ApplicationModule {}