import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Company } from './company.entity';

@Injectable()
export class CompaniesService {
  constructor(
    @InjectRepository(Company)
    private companyRepo: Repository<Company>,
  ) {}

  // 👇 get all companies
  findAll() {
    return this.companyRepo.find();
  }

  // 👇 get one company
  findOne(id: number) {
    return this.companyRepo.findOneBy({ id });
  }

  // 👇 create company
  create(data: Partial<Company>) {
    const company = this.companyRepo.create(data);
    return this.companyRepo.save(company);
  }

  // 👇 delete
  remove(id: number) {
    return this.companyRepo.delete(id);
  }
}