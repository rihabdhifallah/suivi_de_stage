import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Notification } from "./notification.entity";
import { User } from "../users/user.entity";

@Injectable()
export class NotificationService {
  constructor(
    @InjectRepository(Notification)
    private repo: Repository<Notification>,

    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}

  // 🔔 CREATE NOTIFICATION
  async create(
    recipientId: number,
    type: string,
    title: string,
    message?: string,
    entityId?: number,
  ) {
    const user = await this.userRepo.findOne({ where: { id: recipientId } });
    if (!user) throw new Error("Recipient student not found");

    return this.repo.save({
      user,
      type,
      title,
      message,
      entityId,
    });
  }

  // 📥 GET USER NOTIFICATIONS
  async findMyNotifications(userId: number) {
    return this.repo.find({
      where: { user: { id: userId } },
      order: { createdAt: "DESC" },
    });
  }

  // 👁 MARK AS READ
  async markAsRead(id: number) {
    return this.repo.update(id, { read: true });
  }

  // 🧹 DELETE
  async delete(id: number) {
    return this.repo.delete(id);
  }

  // 🔢 UNREAD COUNT
  async countUnread(userId: number) {
    return this.repo.count({
      where: {
        user: { id: userId },
        read: false,
      },
    });
  }
}