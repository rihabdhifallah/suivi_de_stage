import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('departements')
export class Departement {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ unique: true })
  nom!: string;

  @Column({ nullable: true })
  description?: string;
}
