import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Rapport } from './rapport.entity';
import { User } from 'src/users/user.entity';
import * as nodemailer from 'nodemailer';

@Injectable()
export class RapportsService {
  

  constructor(
    @InjectRepository(Rapport)
    private repo: Repository<Rapport>,

    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}

  // ================= CREATE =================
  async create(dto: any, file: any, userId: number) {

  const student = await this.userRepo.findOne({
    where: { id: userId },
    relations: ['encadrant'],
  });
  if (!student) {
  throw new Error("Student not found");
}


  const rapport = this.repo.create({
    title: dto.title,
    type: dto.type,
    resume: dto.resume,
    difficulty: dto.difficulty,
    company: dto.company,
    periode: dto.periode,
    file: file?.filename,

    student,
    encadrant: student.encadrant,

    status: "pending",
  });

  return await this.repo.save(rapport);
}
  // ================= GET ALL =================
  findAll() {
    return this.repo.find({
      relations: ['student', 'encadrant'],
      order: { createdAt: 'DESC' },
    });
  }

  // ================= DELETE =================
  remove(id: number) {
    return this.repo.delete(id);
  }

  // ================= BY ENCADRANT =================
findByEncadrant(id: number) {
  return this.repo
    .createQueryBuilder("rapport")
    .leftJoinAndSelect("rapport.student", "student")
    .leftJoinAndSelect("rapport.encadrant", "encadrant")
    .where("encadrant.id = :id", { id })
    .orderBy("rapport.createdAt", "DESC")
    .getMany();
}

  // ================= BY USER =================
  findByUser(userId: number) {
    return this.repo.find({
      where: { student: { id: userId } },
      relations: ['student', 'encadrant'],
      order: { createdAt: 'DESC' },
    });
  }

  // ================= SHARE REPORT (EMAIL PDF) =================
 async shareReport(rapportId: number, email: string) {

  const rapport = await this.repo.findOne({
    where: { id: rapportId },
    relations: ['student'],
  });

  if (!rapport) throw new Error("Rapport not found");

  const encadrant = await this.userRepo.findOne({
    where: { email },
  });

  if (!encadrant) throw new Error("Encadrant not found");

  rapport.encadrant = encadrant;
  await this.repo.save(rapport);

  const filePath = `./uploads/rapports/${rapport.file}`;

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  await transporter.sendMail({
    from: process.env.EMAIL_USER,
    to: email,
    subject: "📄 Nouveau rapport reçu",
    text: "Un étudiant vous a partagé un rapport à consulter.",
    attachments: [
      {
        filename: rapport.file,
        path: filePath,
      },
    ],
  });

  return { message: "Rapport envoyé ✔" };
}
async addComment(rapportId: number, commentaire: string) {

  const rapport = await this.repo.findOne({
    where: { id: rapportId },
  });

  if (!rapport) {
    throw new Error("Rapport introuvable");
  }

  rapport.commentaire = commentaire;
  rapport.status = "reviewed";

  return await this.repo.save(rapport);
}



async reviewRapport(id: number, dto: any) {
  const rapport = await this.repo.findOne({
    where: { id },
    relations: ['student', 'encadrant'], // 
  });

  if (!rapport) {
    throw new Error("Rapport not found");
  }

  if (dto.status != null) {
    rapport.status = dto.status;
  }

  if (dto.commentaire != null) {
    rapport.commentaire = dto.commentaire;
  }

  await this.repo.save(rapport);

  return this.repo.findOne({
    where: { id },
    relations: ['student', 'encadrant'],
  });
}

findOne(id: number) {
  return this.repo.findOne({
    where: { id },
    relations: ['student', 'encadrant'],
  });
}
}