import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Rapport } from './rapport.entity';
import { RapportsService } from './rapports.service';
import { RapportsController } from './rapports.controller';
import { User } from 'src/users/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Rapport, User])],
  controllers: [RapportsController],
  providers: [RapportsService],
})
export class RapportsModule {}