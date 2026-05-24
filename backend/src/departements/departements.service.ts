import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Departement } from './departement.entity';

@Injectable()
export class DepartementsService {
  constructor(
    @InjectRepository(Departement)
    private readonly repo: Repository<Departement>,
  ) {}

  findAll() {
    return this.repo.find({ order: { nom: 'ASC' } });
  }

  async create(nom: string, description?: string) {
    const exists = await this.repo.findOne({ where: { nom } });
    if (exists) throw new ConflictException('Département déjà existant');
    const d = this.repo.create({ nom, description });
    return this.repo.save(d);
  }

  async update(id: number, nom: string, description?: string) {
    const d = await this.repo.findOne({ where: { id } });
    if (!d) throw new NotFoundException('Département non trouvé');
    d.nom = nom;
    d.description = description;
    return this.repo.save(d);
  }

  async remove(id: number) {
    const d = await this.repo.findOne({ where: { id } });
    if (!d) throw new NotFoundException('Département non trouvé');
    return this.repo.remove(d);
  }
}
