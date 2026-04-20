import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";

@Entity()
export class Notification {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  receiver!: string;

  @Column()
  message!: string;

  @Column({ type: 'text', nullable: true })
  pdf!: string;

  @Column({ default: 'unread' })
status!: string; // unread | accepted | rejected

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt!: Date;
}