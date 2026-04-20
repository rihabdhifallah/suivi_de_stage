import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Task } from './task.entity';
import { CreateTaskDto } from './dto/create-task.dto';

@Injectable()
export class TaskService {
  constructor(
    @InjectRepository(Task)
    private taskRepo: Repository<Task>,
  ) {}

  // CREATE TASK
 async create(dto: CreateTaskDto) {
  const task = this.taskRepo.create({
    titre: dto.titre,
    sender: dto.sender,
    receiver: dto.receiver.toLowerCase().trim(),
    status: dto.status ?? "en attente",
    fac_name: dto.fac_name,
    fac_email: dto.fac_email,
    fac_phone: dto.fac_phone,
    fac_pays: dto.fac_pays,
    message: dto.message,
  });

  return this.taskRepo.save(task);
}


  //  GET ALL
  findAll() {
    return this.taskRepo.find();
  }

  // GET BY RECEIVER
 findByReceiver(email: string) {
  return this.taskRepo.find({
    where: {
      receiver: email.toLowerCase().trim(),
    },
  });
}

  // UPDATE STATUS
  async updateStatus(id: number, status: string) {
    const task = await this.taskRepo.findOne({ where: { id } });

    if (!task) throw new Error('Task not found');

    task.status = status;

    return await this.taskRepo.save(task);
  }
}