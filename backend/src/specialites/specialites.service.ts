import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Specialite } from './specialite.entity';

@Injectable()
export class SpecialitesService {
  constructor(
    @InjectRepository(Specialite)
    private readonly repo: Repository<Specialite>,
  ) {}

  findAll() {
    return this.repo.find({ order: { nom: 'ASC' } });
  }

  findByDepartement(departementId: number) {
    return this.repo.find({ where: { departementId }, order: { nom: 'ASC' } });
  }

  async create(nom: string, description?: string, departementId?: number) {
    const exists = await this.repo.findOne({ where: { nom } });
    if (exists) throw new ConflictException('Spécialité déjà existante');
    const s = this.repo.create({ nom, description, departementId });
    return this.repo.save(s);
  }

  async update(id: number, nom: string, description?: string, departementId?: number) {
    const s = await this.repo.findOne({ where: { id } });
    if (!s) throw new NotFoundException('Spécialité non trouvée');
    s.nom = nom;
    s.description = description;
    if (departementId !== undefined) s.departementId = departementId;
    return this.repo.save(s);
  }

  async remove(id: number) {
    const s = await this.repo.findOne({ where: { id } });
    if (!s) throw new NotFoundException('Spécialité non trouvée');
    return this.repo.remove(s);
  }
}
