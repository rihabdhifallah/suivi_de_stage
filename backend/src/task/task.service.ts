import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { Task } from './task.entity';
import { CreateTaskDto } from './dto/create-task.dto';
import { NotificationService } from '../notifications/notifications.service';
import { User } from '../users/user.entity';

@Injectable()
export class TaskService {
  constructor(
    @InjectRepository(Task)
    private taskRepo: Repository<Task>,

    private entityManager: EntityManager,

    private notificationService: NotificationService,
  ) {}

  // ── Helper: find user by email via EntityManager ──
  private async findUserByEmail(email: string): Promise<User | null> {
    try {
      return await this.entityManager.findOne(User, {
        where: { email: email.toLowerCase().trim() },
      });
    } catch {
      return null;
    }
  }

  // ── CREATE ──
  async create(dto: CreateTaskDto) {
    const task = this.taskRepo.create({
      titre: dto.titre,
      sender: dto.sender,
      receiver: dto.receiver.toLowerCase().trim(),
      status: dto.status ?? 'en attente',
      fac_name: dto.fac_name,
      fac_email: dto.fac_email,
      fac_phone: dto.fac_phone,
      fac_pays: dto.fac_pays,
      message: dto.message,
      comment: dto.comment,
    });
    const saved = await this.taskRepo.save(task);

    // Notify encadrant of new task
    try {
      const receiver = await this.findUserByEmail(saved.receiver);
      if (receiver) {
        await this.notificationService.create(
          receiver.id,
          'task',
          `Nouvelle tâche : ${saved.titre}`,
          `L'étudiant ${saved.sender} vous a soumis une nouvelle tâche.`,
          saved.id,
        );
      }
    } catch (e) {
      console.warn('Notif create task:', e);
    }

    return saved;
  }

  // ── GET ALL ──
  findAll() {
    return this.taskRepo.find();
  }

  // ── GET BY RECEIVER ──
  findByReceiver(email: string) {
    return this.taskRepo.find({
      where: { receiver: email.toLowerCase().trim() },
    });
  }

  // ── GET BY SENDER ──
  findBySender(email: string) {
    return this.taskRepo.find({
      where: { sender: email.toLowerCase().trim() },
    });
  }

  // ── UPDATE STATUS & COMMENT ──
  async updateStatus(id: number, status: string, comment?: string) {
    const task = await this.taskRepo.findOne({ where: { id } });
    if (!task) throw new Error('Task not found');

    const oldStatus = task.status;
    task.status = status;
    if (comment !== undefined) task.comment = comment;
    const saved = await this.taskRepo.save(task);

    try {
      // Student moves to "a tester" → notify encadrant
      if (status === 'a tester' && oldStatus !== 'a tester') {
        const receiver = await this.findUserByEmail(saved.receiver);
        if (receiver) {
          await this.notificationService.create(
            receiver.id,
            'task_a_tester',
            `Tâche à tester : ${saved.titre}`,
            `L'étudiant ${saved.sender} a soumis la tâche pour test.`,
            saved.id,
          );
        }
      }

      // Student marks "terminee" → notify encadrant
      if (status === 'terminee' && oldStatus !== 'terminee') {
        const receiver = await this.findUserByEmail(saved.receiver);
        if (receiver) {
          await this.notificationService.create(
            receiver.id,
            'task_terminee',
            `Tâche terminée : ${saved.titre}`,
            `L'étudiant ${saved.sender} a marqué la tâche comme terminée.`,
            saved.id,
          );
        }
      }

      // Encadrant validates or rejects → notify student
      if ((status === 'validee' || status === 'rejetee') && oldStatus !== status) {
        const sender = await this.findUserByEmail(saved.sender);
        if (sender) {
          const ok = status === 'validee';
          await this.notificationService.create(
            sender.id,
            'task_evaluated',
            ok
              ? `Tâche validée : ${saved.titre}`
              : `Tâche rejetée : ${saved.titre}`,
            ok
              ? `Votre encadrant a validé votre tâche.${comment ? ' Commentaire : ' + comment : ''}`
              : `Votre encadrant a rejeté votre tâche.${comment ? ' Commentaire : ' + comment : ''}`,
            saved.id,
          );
        }
      }

      // Encadrant sets "en cours" → notify student
      if (status === 'en cours' && oldStatus !== 'en cours') {
        const sender = await this.findUserByEmail(saved.sender);
        if (sender) {
          await this.notificationService.create(
            sender.id,
            'task_in_progress',
            `Tâche en cours : ${saved.titre}`,
            `Votre encadrant a pris en charge votre tâche.`,
            saved.id,
          );
        }
      }
    } catch (e) {
      console.warn('Notif updateStatus:', e);
    }

    return saved;
  }
}
