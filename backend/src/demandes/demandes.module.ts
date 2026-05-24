import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DemandesController } from './demandes.controller';
import { DemandesService } from './demandes.service';
import { Demande } from './demande.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Demande]) //    
  ],
  controllers: [DemandesController],
  providers: [DemandesService],
})
export class DemandesModule {} 