import { Injectable, BadRequestException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { EncadrantProfessionnel } from "../EncadrantExterne/encadrantprofentity";
import { User } from "../users/user.entity";
import { MailService } from "../mail/mail.service";
import * as bcrypt from "bcrypt";

@Injectable()
export class EncadrantService {
  constructor(
    @InjectRepository(EncadrantProfessionnel)
    private repo: Repository<EncadrantProfessionnel>,

    @InjectRepository(User)
    private userRepo: Repository<User>,

    private mailService: MailService,
  ) {}

  async create(data: any) {
    if (!data.email || !data.email.trim()) {
      throw new BadRequestException("L'email est obligatoire");
    }
    const emailClean = data.email.toLowerCase().trim();
    if (!emailClean.endsWith("@gmail.com")) {
      throw new BadRequestException("L'email doit obligatoirement être une adresse Gmail (ex: exemple@gmail.com)");
    }

    // 1. Generate random 10-char password
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#';
    const randomPassword = Array.from({ length: 10 }, () =>
      chars[Math.floor(Math.random() * chars.length)]
    ).join('');

    // 2. Hash password and create User record if not exists
    let user = await this.userRepo.findOne({ where: { email: emailClean } });
    if (!user) {
      const hashedPassword = await bcrypt.hash(randomPassword, 10);
      user = this.userRepo.create({
        name: data.nomComplet,
        email: emailClean,
        password: hashedPassword,
        role: 'encadrant-professionnel',
        status: 'active',
        poste: data.poste ?? '',
        phone: data.telephone ?? '',
        adresse: data.adresse ?? '',
        companyId: data.companyId ? Number(data.companyId) : undefined,
      });
      await this.userRepo.save(user);
    }

    // 3. Save EncadrantProfessionnel record
    const saved = await this.repo.save({
      nomComplet: data.nomComplet,
      email: emailClean,
      poste: data.poste ?? '',
      telephone: data.telephone ?? '',
      adresse: data.adresse ?? '',
      companyId: data.companyId ? Number(data.companyId) : undefined,
    });

    // 4. Send email (non-blocking)
    try {
      await this.mailService.sendProfessionalCredentials(
        emailClean,
        data.nomComplet,
        randomPassword,
      );
    } catch (e) {
      console.log('Email send failed (non-blocking):', e);
    }

    // 5. Return credentials so frontend can display them too
    return {
      ...saved,
      password: randomPassword,
    };
  }

  findByCompany(companyId: number) {
    return this.repo.find({ where: { companyId } });
  }

  findAll() {
    return this.repo.find({ order: { id: 'DESC' } });
  }

  async update(id: number, data: any) {
    await this.repo.update(id, {
      nomComplet: data.nomComplet,
      poste: data.poste,
      telephone: data.telephone,
      adresse: data.adresse,
    });
    // Also update the User record
    const enc = await this.repo.findOne({ where: { id } });
    if (enc) {
      await this.userRepo.update(
        { email: enc.email },
        { name: data.nomComplet, poste: data.poste, phone: data.telephone, adresse: data.adresse },
      );
    }
    return this.repo.findOne({ where: { id } });
  }

  async delete(id: number) {
    const enc = await this.repo.findOne({ where: { id } });
    if (enc) {
      // Delete the corresponding user if exists
      const user = await this.userRepo.findOne({ where: { email: enc.email } });
      if (user) {
        await this.userRepo.delete(user.id);
      }
      await this.repo.delete(id);
    }
  }
}