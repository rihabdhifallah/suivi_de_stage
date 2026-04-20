// notifications.service.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from './notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
  @InjectRepository(Notification)
  private repo: Repository<Notification>,
) {}

  findByCompany(email: string) {
    return this.repo.find({
      where: { receiver: email },
      order: { createdAt: 'DESC' },
    });
  }

  async markAsRead(id: number) {
    return this.repo.update(id, { status: 'read' });
  }

  async createNotification(body: any) {
  return this.repo.save({
    receiver: body.email,
    message: body.message,
    pdf: body.pdf,
    status: 'unread',
  });
}
async updateStatus(id: number, status: string) {
  return this.repo.update(id, { status });
}
}