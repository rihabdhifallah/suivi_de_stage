import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class Rapport {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  studentId!: number;

  @Column()
  file!: string;
}