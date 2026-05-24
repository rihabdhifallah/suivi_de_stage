import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Presentation } from "./presentation.entity";
import { User } from "../users/user.entity";
import { Encadrement } from "../encadrement/encadrement.entity";

@Injectable()
export class PresentationsService {
  constructor(
    @InjectRepository(Presentation)
    private repo: Repository<Presentation>,

    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}

  async create(dto: any, file: Express.Multer.File, user: any) {

  console.log("==== DEBUG START ====");
  console.log("USER =>", user);
  console.log("DTO =>", dto);
  console.log("FILE =>", file);
  console.log("FILE NAME =>", file?.filename);
  console.log("==== DEBUG END ====");

  if (!file) {
    throw new Error("FILE IS MISSING");
  }

  const student = await this.userRepo.findOne({
    where: { id: user.userId },
    relations: { encadrant: true },
  });

  if (!student) {
    throw new Error("STUDENT NOT FOUND");
  }

  let encadrant = student.encadrant;
  if (!encadrant) {
    const enc = await this.userRepo.manager.getRepository(Encadrement).findOne({
      where: { student: { id: student.id } },
      relations: ["encadrant"],
    });
    if (enc) {
      encadrant = enc.encadrant;
      // Proactively sync user.encadrant to maintain database consistency
      student.encadrant = encadrant;
      await this.userRepo.save(student);
    }
  }

  if (!encadrant) {
    throw new Error("Aucun encadrant académique assigné pour cet étudiant. Veuillez contacter l'administration.");
  }

  return this.repo.save(
    this.repo.create({
      titre: dto.titre,
      type: dto.type,
      date: dto.date,
      file: file.filename || "no-file",

      student,
      encadrant,

      encadrantName: `${encadrant.name ?? ""} ${encadrant.prenom ?? ""}`.trim(),
      encadrantEmail: encadrant.email,
      encadrantEtablissement: encadrant.etablissement || student.niveau || "Académique",

      status: "en_attente",
    }),
  );
}

  async findByStudent(studentId: number) {
    return this.repo.find({
      where: { student: { id: studentId } },
      relations: ["encadrant"],
      order: { createdAt: "DESC" },
    });
  }

  async findByEncadrant(encadrantId: number) {
    return this.repo.find({
      where: { encadrant: { id: encadrantId } },
      relations: ["student"],
      order: { createdAt: "DESC" },
    });
  }

  async review(id: number, dto: { status?: string; comment?: string }) {
    const pres = await this.repo.findOne({ where: { id } });
    if (!pres) throw new Error("Présentation introuvable");
    if (dto.status !== undefined) pres.status = dto.status;
    if (dto.comment !== undefined) pres.comment = dto.comment;
    return this.repo.save(pres);
  }
}