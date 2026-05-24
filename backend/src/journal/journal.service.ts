import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Journal } from "./journal.entity";
import { CreateJournalDto } from "./dto/create-journal.dto";

@Injectable()
export class JournalService {
  constructor(
    @InjectRepository(Journal)
    private repo: Repository<Journal>,
  ) {}

  //  CREATE
  async create(studentId: number, dto: CreateJournalDto) {
      console.log("DTO RECEIVED =>", dto); // 
      console.log(" studentId =", studentId);
      console.log("DTO KEYS:", Object.keys(dto));
console.log("DTO FULL:", dto);


  const saved = await this.repo.save({
    studentId,
    ...dto,
  });

  console.log("SAVED IN DB:", saved);

  return saved;
}

  //  GET ALL (student only)
  

  //  GET ONE
  findOne(id: number) {
    return this.repo.findOneBy({ id });
  }

  //  DELETE
  delete(id: number) {
    return this.repo.delete(id);
  }
  findByStudent(studentId: number) {
  return this.repo.find({
    where: { studentId },
    order: { id: "DESC" },
    select: {
      id: true,
      title: true,
      tasksDone: true,
      learned: true,
      mood: true,
      severity: true,
      tags: true,
      difficulties: true,
      createdAt: true,
    },
  });
}

  async update(id: number, dto: any) {
    await this.repo.update(id, dto);
    return this.repo.findOneBy({ id });
  }
}
