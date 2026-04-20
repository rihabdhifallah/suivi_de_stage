import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Stage } from './stage.entity';
import { StageStatus } from './stage-status.enum';
import { Notification } from '../notifications/notification.entity';

@Injectable()
export class StageService {
  constructor(
    @InjectRepository(Stage)
    private readonly stageRepo: Repository<Stage>,

    @InjectRepository(Notification)
    private readonly notificationRepo: Repository<Notification>,
  ) {}

  // ================= GET ALL (ADMIN)
  findAll() {
    return this.stageRepo.find();
  }

  // ================= CREATE ADMIN STAGE
  async createAdminStage(data: any) {
    const stage = await this.stageRepo.save({
      ...data,
      status: StageStatus.PENDING,
      type: 'admin_offer',
    });

    // 🔔 notification
    await this.notificationRepo.save({
      receiver: stage.company,
      message: `New stage "${stage.title}" created`,
      status: 'unread',
      createdAt: new Date(),
    });

    return stage;
  }

  // ================= CREATE STUDENT
  createStudentProposal(data: any) {
    return this.stageRepo.save({
      ...data,
      status: StageStatus.PENDING,
      type: 'student_proposal',
    });
  }

  // ================= CREATE COMPANY
  createCompanyStage(data: any) {
    return this.stageRepo.save({
      ...data,
      status: StageStatus.PENDING,
      type: 'company_offer',
    });
  }

  // ================= UPDATE
  async updateStage(id: number, body: any) {
    await this.stageRepo.update(id, body);
    return this.stageRepo.findOne({ where: { id } });
  }

  // ================= DELETE
  async deleteStage(id: number) {
    return this.stageRepo.delete(id);
  }

  // ================= ACCEPT
  async accept(id: number) {
    return this.updateStatus(id, StageStatus.ACCEPTED);
  }

  // ================= REJECT
  async reject(id: number) {
    return this.updateStatus(id, StageStatus.REJECTED);
  }

  // ================= PUBLISH
  async publish(id: number) {
    const stage = await this.stageRepo.findOne({ where: { id } });

    if (!stage) throw new Error('Stage not found');

    stage.published = true;
    await this.stageRepo.save(stage);

    // 🔔 notification
    await this.notificationRepo.save({
      receiver: stage.company,
      message: `Stage "${stage.title}" is now published`,
      status: 'unread',
      createdAt: new Date(),
    });

    return stage;
  }

  // ================= STATUS CHANGE
  async updateStatus(id: number, status: StageStatus) {
    const stage = await this.stageRepo.findOne({ where: { id } });

    if (!stage) throw new Error('Stage not found');

    if (stage.status !== StageStatus.PENDING) {
      throw new Error('Already processed');
    }

    stage.status = status;
    await this.stageRepo.save(stage);

    // 🔔 notification
    await this.notificationRepo.save({
      receiver: stage.company,
      message: `Stage "${stage.title}" → ${status}`,
      status: 'unread',
      createdAt: new Date(),
    });

    return stage;
  }

  // ================= GET COMPANY STAGES
  findByCompany(company: string) {
    return this.stageRepo.find({
      where: { company },
      order: { id: 'DESC' },
    });
  }

  // ================= GET NOTIFICATIONS
  getNotifications(company: string) {
    return this.notificationRepo.find({
      where: { receiver: company },
      order: { createdAt: 'DESC' },
    });
  }
}