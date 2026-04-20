import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { CreateUserDto } from './dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {}


  findAll() {
    return this.repo.find();
  }

  async findCompanies() {
    const companies = await this.repo.find({
      where: { role: 'company' },
    });

    console.log(companies); //ي

    return companies;
  }
  async create(dto: CreateUserDto) {
  return this.repo.save({
    ...dto,
    country: dto.country ?? '',
    phone: dto.phone ?? '',
    universite: dto.universite ?? '',
  });
}
}