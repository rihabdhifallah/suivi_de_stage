import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Demande } from './demande.entity';
import { CreateDemandeDto } from './dto/create-demande.dto';

@Injectable()
export class DemandesService {
  prisma: any;
  constructor(
    @InjectRepository(Demande)
    private repo: Repository<Demande>,
  ) {}

  
async create(body: any, files: any) {
  const demande = this.repo.create({
    student_id: body.student_id,

    // step 1
    specialite: body.specialite,
    duree: body.duree,
    date_prevue: body.date,

    // entreprise
    entreprise: body.entreprise,
    secteur: body.secteur,
    adresse: body.adresse,
    telephone_entreprise: body.telephone_entreprise,
    email_entreprise: body.email_entreprise,

    // encadrant
    encadrant_nom: body.encadrant_nom,
    encadrant_poste: body.encadrant_poste,
    encadrant_tel: body.encadrant_tel,
    encadrant_email: body.encadrant_email,

    // step 3
    titre: body.titre,
    mission: body.mission,
    skills: body.skills,
    date_debut: body.date_debut,
    date_fin: body.date_fin,
    remuneration: body.remuneration,
    found_via: body.found_via,
    note: body.note,

    // files
    cv: files?.cv?.[0]?.filename,
    lettre: files?.lettre?.[0]?.filename,

    status: body.status ?? "en attente",
  });

  return this.repo.save(demande);
}
  findAll() {
    return this.repo.find();
  }

  findByStudent(id: number) {
    return this.repo.find({ where: { student_id: id } });
  }

  
 
async updateStatus(id: number, status: string) {
  return this.prisma.demande.update({
    where: { id },
    data: { status },
  });
}
}