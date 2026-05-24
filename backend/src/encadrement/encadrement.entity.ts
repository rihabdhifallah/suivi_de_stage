import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { User } from '../users/user.entity';

@Entity('encadrements')
export class Encadrement {

  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  annee!: string;

  @Column()
  niveau!: string;

  @Column()
  specialite!: string;

 @ManyToOne(() => User)
encadrant!: User;

@ManyToOne(() => User)
student!: User;

  @Column({ default: 'pending' })
  status!: string;

  @Column({ nullable: true })
  sentAt!: Date;
}