import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Reunion } from './reunion.entity';
import { User } from '../users/user.entity';
import { NotificationService } from '../notifications/notifications.service';

@Injectable()
export class ReunionsService {
  constructor(
    @InjectRepository(Reunion)
    private repo: Repository<Reunion>,

    @InjectRepository(User)
    private userRepo: Repository<User>,

    private notificationService: NotificationService,
  ) {}

  async getReunionsForUser(email: string, role: string) {
    const allReunions = await this.repo.find({
      relations: ['participants', 'creator'],
      order: { id: 'DESC' },
    });
    return allReunions.filter(reunion => 
      reunion.creator?.email === email || reunion.participants?.some(p => p.email === email)
    );
  }

  async createReunion(body: any, creatorEmail: string) {
    const creator = await this.userRepo.findOne({ where: { email: creatorEmail } });
    if (!creator) throw new Error("Creator not found");

    const participantEmails = body.participantEmails || [];
    const participants: User[] = [];
    for (const email of participantEmails) {
      const u = await this.userRepo.findOne({ where: { email } });
      if (u) {
        participants.push(u);
      }
    }

    const reunion = this.repo.create({
      titre: body.titre,
      date: body.date,
      heure: body.heure,
      plateforme: body.plateforme,
      lien: body.lien,
      statut: 'planifiee',
      creator,
      participants,
    });

    const savedReunion = await this.repo.save(reunion);

    // Create notifications for each participant student
    for (const student of participants) {
      try {
        await this.notificationService.create(
          student.id,
          'reunion',
          'Nouvelle réunion planifiée',
          `${creator.name} ${creator.prenom || ''} vous a invité à la réunion : "${body.titre}"`,
          savedReunion.id
        );
      } catch (e) {
        console.error(`Error notifying student ${student.email}:`, e);
      }
    }

    return savedReunion;
  }
}
