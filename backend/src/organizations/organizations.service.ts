import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Organization } from './organizations.entity';

@Injectable()
export class OrganizationsService {
  constructor(
    @InjectRepository(Organization)
    private repo: Repository<Organization>,
  ) {}

  async search(q: string) {
    return this.repo
      .createQueryBuilder('org')
      .where('LOWER(org.name) LIKE LOWER(:q)', { q: `%${q}%` })
      .orWhere('LOWER(org.city) LIKE LOWER(:q)', { q: `%${q}%` })
      .orWhere('LOWER(org.country) LIKE LOWER(:q)', { q: `%${q}%` })
      .orWhere('LOWER(org.industry) LIKE LOWER(:q)', { q: `%${q}%` })
      .getMany();
  }

  findAll() {
    return this.repo.find();
  }
}