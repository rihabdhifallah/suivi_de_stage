import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Specialite } from './specialite.entity';
import { SpecialitesService } from './specialites.service';
import { SpecialitesController } from './specialites.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Specialite])],
  controllers: [SpecialitesController],
  providers: [SpecialitesService],
  exports: [SpecialitesService],
})
export class SpecialitesModule {}
