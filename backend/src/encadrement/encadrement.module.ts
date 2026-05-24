import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Encadrement } from './encadrement.entity';
import { EncadrementService } from './encadrement.service';
import { EncadrementController } from './encadrement.controller';
import { User } from 'src/users/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Encadrement,User])],
  controllers: [EncadrementController],
  providers: [EncadrementService],
})
export class EncadrementModule {}