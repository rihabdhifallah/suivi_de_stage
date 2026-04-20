import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class Task {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  titre!: string;

  @Column()
  sender!: string;

  @Column()
  receiver!: string;

  @Column({ default: 'en attente' })
  status!: string;

  @Column({ nullable: true })
  fac_name?: string;

  @Column({ nullable: true })
  fac_email?: string;

  @Column({ nullable: true })
  fac_phone?: string;

  @Column({ nullable: true })
  fac_pays?: string;

  @Column({ nullable: true, type: 'text' })
  message?: string;
}