import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message } from './message.entity';
import { User } from '../users/user.entity';

@Injectable()
export class MessagesService {
  constructor(
    @InjectRepository(Message) private repo: Repository<Message>,
    @InjectRepository(User)    private userRepo: Repository<User>,
  ) {}

  /** Envoyer un message */
  async send(senderEmail: string, receiverEmail: string, content: string) {
    const sender   = await this.userRepo.findOne({ where: { email: senderEmail.toLowerCase() } });
    const receiver = await this.userRepo.findOne({ where: { email: receiverEmail.toLowerCase() } });
    if (!sender || !receiver) throw new Error('Utilisateur introuvable');

    return this.repo.save({ sender, receiver, content, read: false });
  }

  /** Récupérer la conversation entre deux utilisateurs */
  async getConversation(emailA: string, emailB: string) {
    const a = emailA.toLowerCase();
    const b = emailB.toLowerCase();

    const messages = await this.repo
      .createQueryBuilder('m')
      .leftJoinAndSelect('m.sender',   's')
      .leftJoinAndSelect('m.receiver', 'r')
      .where(
        '(LOWER(s.email) = :a AND LOWER(r.email) = :b) OR (LOWER(s.email) = :b AND LOWER(r.email) = :a)',
        { a, b },
      )
      .orderBy('m.createdAt', 'ASC')
      .getMany();

    // Marquer comme lus les messages reçus par A
    const unread = messages.filter(
      m => LOWER(m.receiver.email) === a && !m.read,
    );
    if (unread.length > 0) {
      await this.repo.update(unread.map(m => m.id), { read: true });
    }

    return messages.map(m => ({
      id:        m.id,
      content:   m.content,
      createdAt: m.createdAt,
      read:      m.read,
      sender:   { id: m.sender.id,   email: m.sender.email,   name: m.sender.name },
      receiver: { id: m.receiver.id, email: m.receiver.email, name: m.receiver.name },
    }));
  }

  /** Liste des conversations (derniers messages) pour un utilisateur */
  async getConversationList(userEmail: string) {
    const email = userEmail.toLowerCase();

    const rows = await this.repo.manager.query(`
      SELECT DISTINCT ON (
        LEAST(LOWER(s.email), LOWER(r.email)),
        GREATEST(LOWER(s.email), LOWER(r.email))
      )
        m.id,
        m.content,
        m."createdAt",
        m.read,
        s.id   AS "senderId",   s.email AS "senderEmail",   s.name AS "senderName",   s.photo AS "senderPhoto",
        r.id   AS "receiverId", r.email AS "receiverEmail", r.name AS "receiverName", r.photo AS "receiverPhoto"
      FROM messages m
      INNER JOIN users s ON s.id = m."senderId"
      INNER JOIN users r ON r.id = m."receiverId"
      WHERE LOWER(s.email) = $1 OR LOWER(r.email) = $1
      ORDER BY
        LEAST(LOWER(s.email), LOWER(r.email)),
        GREATEST(LOWER(s.email), LOWER(r.email)),
        m."createdAt" DESC
    `, [email]);

    return rows.map((row: any) => {
      const isSender = row.senderEmail.toLowerCase() === email;
      const other = isSender
        ? { id: row.receiverId, email: row.receiverEmail, name: row.receiverName, photo: row.receiverPhoto }
        : { id: row.senderId,   email: row.senderEmail,   name: row.senderName,   photo: row.senderPhoto };
      return {
        lastMessageId:      row.id,
        lastMessageContent: row.content,
        lastMessageDate:    row.createdAt,
        read:               row.read,
        other,
      };
    });
  }

  /** Nombre de messages non lus */
  async countUnread(userEmail: string) {
    const email = userEmail.toLowerCase();
    return this.repo
      .createQueryBuilder('m')
      .innerJoin('m.receiver', 'r')
      .where('LOWER(r.email) = :email AND m.read = false', { email })
      .getCount();
  }
}

function LOWER(s: string) { return s?.toLowerCase() ?? ''; }
