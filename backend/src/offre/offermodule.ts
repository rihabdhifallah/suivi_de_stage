import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Offre } from "./offre.entity";
import { OffreService } from "./offre.service";
import { OffreController } from "./offre.controller";
import { PassportModule } from "@nestjs/passport";

@Module({
  imports: [
    TypeOrmModule.forFeature([Offre]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
  ],
  providers: [OffreService],
  controllers: [OffreController],
})
export class OffreModule {}