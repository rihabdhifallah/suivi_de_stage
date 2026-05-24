import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Stage, StageStatus } from './stage.entity';

@Injectable()
export class StagesService {
 
  constructor(
    @InjectRepository(Stage)
    private stageRepo: Repository<Stage>,
  ) {}

 async create(dto: any) {
  const stage = this.stageRepo.create({
    titre: dto.titre,
    domaine: dto.domaine,
    duree: dto.duree,
    niveau: dto.niveau,
    places: Number(dto.places),
    companyEmail: dto.companyEmail,
    status: StageStatus.PUBLISHED,
    active: true,
  } as any); 
  return this.stageRepo.save(stage);
}
 findAll() {
  return this.stageRepo.find({
    where: {
      status: StageStatus.PUBLISHED,
      active: true,
    },
  });

}
  
findPublishedForStudents() {
  return this.stageRepo.find({
    where: {
      status: StageStatus.PUBLISHED,
      active: true,
    },
  });
}
  updateStatus(id: number, status: StageStatus) {
    return this.stageRepo.update(id, { status });
  }

  findCompanyStages(email: string) {
    return this.stageRepo.find({
      where: { companyEmail: email },
    });
  }
  findForStudents() {
  return this.stageRepo.find({
    where: {
      status: StageStatus.PUBLISHED,
      active: true,
    },
  });
}
}