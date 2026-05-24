import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('specialites')
export class Specialite {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ unique: true })
  nom!: string;

  @Column({ nullable: true })
  description?: string;

  @Column({ nullable: true })
  departementId?: number;
}
