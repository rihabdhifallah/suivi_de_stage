import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  ManyToMany,
  JoinTable,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

@Entity('reunions')
export class Reunion {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  titre!: string;

  @Column()
  date!: string;

  @Column()
  heure!: string;

  @Column()
  plateforme!: string;

  @Column()
  lien!: string;

  @Column({ default: 'planifiee' })
  statut!: string;

  @ManyToOne(() => User)
  creator!: User;

  @ManyToMany(() => User)
  @JoinTable({ name: 'reunion_participants' })
  participants!: User[];

  @CreateDateColumn()
  createdAt!: Date;
}
