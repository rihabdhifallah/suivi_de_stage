import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Company } from './company.entity';
import { CreateCompanyDto } from './dto/create-company.dto';
import * as bcrypt from 'bcrypt';
import { MailService } from 'src/mail/mail.service';

@Injectable()
export class CompaniesService {
  constructor(
    @InjectRepository(Company)
    private repo: Repository<Company>,
    private mailService: MailService,
  ) {}

  // ================= CREATE COMPANY =================
  async create(dto: CreateCompanyDto) {
  const email = dto.email?.trim()?.toLowerCase();

  if (!email) {
    throw new BadRequestException('Email is required');
  }

  // 🔥 CLEAN CHECK (IMPORTANT)
  const exists = await this.repo.findOne({
    where: { email },
  });

  if (exists) {
    throw new BadRequestException('Email already exists');
  }

  const plainPassword = Math.random().toString(36).slice(-8);
  const hashedPassword = await bcrypt.hash(plainPassword, 10);

  const company = this.repo.create({
    nom: dto.nom,
    email,
    telephone: dto.telephone,
    adresse: dto.adresse,
    secteurActivite: dto.secteurActivite,
    password: hashedPassword,
    role: 'company',
  });

  await this.repo.save(company);

  try {
    await this.mailService.sendCompanyMail(email, plainPassword);
  } catch (err) {
    console.log("MAIL ERROR:", err);
  }

  return { message: 'Company created successfully' };
}

  // ================= GET ALL =================
  findAll() {
    return this.repo.find();
  }

  // ================= GET ONE =================
  findOne(id: number) {
    return this.repo.findOne({ where: { id } });
  }

  // ================= DELETE =================
  async remove(id: number) {
    await this.repo.delete(id);
    return { message: 'Deleted' };
  }

  // ================= UPDATE =================
  async update(id: number, dto: Partial<CreateCompanyDto>) {
    await this.repo.update(id, dto);
    return this.findOne(id);
  }

  // ================= ARCHIVE =================
  async archive(id: number) {
    const company = await this.repo.findOne({ where: { id } });
    if (!company) throw new BadRequestException('Company not found');
    const newStatus = company.status === 'archived' ? 'active' : 'archived';
    await this.repo.update(id, { status: newStatus });
    return { status: newStatus };
  }

  // ================= LOGIN (FIXED 100%) =================
 async login(body: any) {
  console.log("LOGIN BODY =", body);

  const email = body.email?.trim().toLowerCase();

  const company = await this.repo.findOne({
    where: { email },
  });

  console.log("COMPANY FOUND =", company);

  if (!company) {
    throw new UnauthorizedException('Email incorrect');
  }

  if (company.status === 'archived') {
    throw new UnauthorizedException('Votre compte a été archivé. Connexion impossible.');
  }

  const match = await bcrypt.compare(body.password, company.password);

  if (!match) {
    throw new UnauthorizedException('Password incorrect');
  }

  return {
    message: 'Login success',
    access_token: 'dummy-token',
    id: company.id,
    email: company.email,
    role: company.role,   // 
    nom: company.nom,
  };
}
}