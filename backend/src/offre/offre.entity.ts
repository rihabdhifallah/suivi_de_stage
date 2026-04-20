import { Entity, PrimaryGeneratedColumn, Column } from "typeorm";

@Entity()
export class Offre {

  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  titre!: string;

  @Column()
  domaine!: string;

  @Column()
  duree!: string;

  @Column()
  niveau!: string;

  @Column()
  places!: number;

  @Column()
  companyEmail!: string;
  @Column({ default: true })
active!: boolean;
}