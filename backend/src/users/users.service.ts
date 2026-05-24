import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { CreateUserDto } from './dto/create-user.dto';
  import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {}
  

  async findCompanies() {
    const companies = await this.repo.find({
      where: { role: 'company' },
    });

    console.log(companies); //

    return companies;
  }

  async findAcademic() {
    const companies = await this.repo.find({
      where: { role: 'encadrant-academique' },
    });

    console.log(companies); //

    return companies;
  }

async create(dto: CreateUserDto) {
  const plainPassword = dto.password ?? '123456';

  const user = this.repo.create({
    name: dto.name,
    email: dto.email.toLowerCase().trim(),

    password: await bcrypt.hash(plainPassword, 10),

    role: dto.role ?? 'student', //

    phone: dto.phone ?? '',
    country: dto.country ?? '',
    universite: dto.universite ?? '',
    specialite: dto.specialite ?? '',
  });

  return this.repo.save(user);
}
findAll() {
  console.log("REPO =", this.repo);

  return this.repo.find({
    relations: ['encadrant'],
  });
}

}