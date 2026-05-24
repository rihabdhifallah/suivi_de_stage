import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Encadrement } from './encadrement.entity';
import { User } from 'src/users/user.entity';

@Injectable()
export class EncadrementService {
  constructor(
    @InjectRepository(Encadrement)
    private repo: Repository<Encadrement>,

    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}

  // CREATE
  async create(data: any) {

    const student = await this.userRepo.findOne({
      where: { email: data.emailEtudiant }
    });

   const encadrant = await this.userRepo.findOne({
    where: { id: data.encadrantId } 
  });

    if (!student || !encadrant) {
      throw new Error("Student or Encadrant not found");
    }

    const enc = this.repo.create({
      annee: data.annee,
      niveau: data.niveau,
      specialite: data.specialite,
      student,
      encadrant,
    });

    const saved = await this.repo.save(enc);

    // Sync encadrant field directly on User entity
    student.encadrant = encadrant;
    await this.userRepo.save(student);

    return this.repo.findOne({
      where: { id: saved.id },
      relations: ["student", "encadrant"], 
    });  }

  async findAll() {
    const enc = await this.repo.find({
      relations: ["student", "encadrant"],
      order: { id: "DESC" },
    });

    return enc.filter(
      (e) => e.encadrant?.role === "academique" || e.encadrant?.role === "encadrant-academique"
    );
  }

  findByStudent(email: string) {
    return this.repo.find({
      where: { student: { email } },
      relations: ["encadrant", "student"],
      order: { id: "DESC" },
    });
  }

  findByEncadrant(email: string) {
    return this.repo.find({
      where: { encadrant: { email } },
      relations: ["student", "encadrant"],
      order: { id: "DESC" },
    });
  }

  async sendMessage(id: number) {
    const enc = await this.repo.findOne({
      where: { id },
      relations: ["student", "encadrant"],
    });

    if (!enc) throw new Error("Encadrement not found");

    enc.status = "sent";
    enc.sentAt = new Date();

    await this.repo.save(enc);

    console.log(" STUDENT:", enc.student.email);
    console.log(" ENCADRANT:", enc.encadrant.email);

    return { message: "Sent successfully" };
  }

  remove(id: number) {
    return this.repo.delete(id);
  }
}