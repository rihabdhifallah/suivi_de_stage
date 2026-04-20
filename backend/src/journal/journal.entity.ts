import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('journals')
export class Journal {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  studentId!: number;

  @Column()
  date!: string;

  @Column()
  description!: string; // 

  @Column()
  difficulties!: string; 

  @Column()
  solution!: string; 
 
}