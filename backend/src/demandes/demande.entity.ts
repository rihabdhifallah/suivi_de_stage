import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class Demande {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  student_id!: number;

  // STEP 1
  @Column({ nullable: true })
  specialite!: string;

  @Column({ nullable: true })
  duree!: string;

  @Column({ nullable: true })
  date_prevue!: string;

  // ENTREPRISE
  @Column({ nullable: true })
  entreprise!: string;

  @Column({ nullable: true })
  secteur!: string;

  @Column({ nullable: true })
  adresse!: string;

  @Column({ nullable: true })
  telephone_entreprise!: string;

  @Column({ nullable: true })
  email_entreprise!: string;

  // ENCADRANT
  @Column({ nullable: true })
  encadrant_nom!: string;

  @Column({ nullable: true })
  encadrant_poste!: string;

  @Column({ nullable: true })
  encadrant_tel!: string;

  @Column({ nullable: true })
  encadrant_email!: string;

  // STEP 3
  @Column({ nullable: true })
  titre!: string;

  @Column({ type: 'text', nullable: true })
  mission!: string;

  @Column({ type: 'text', nullable: true })
  skills!: string;

  @Column({ nullable: true })
  date_debut!: string;

  @Column({ nullable: true })
  date_fin!: string;

  @Column({ nullable: true })
  remuneration!: string;

  @Column({ nullable: true })
  found_via!: string;

  @Column({ type: 'text', nullable: true })
  note!: string;

  // FILES
  @Column({ nullable: true })
  cv!: string;

  @Column({ nullable: true })
  lettre!: string;

  @Column({ default: 'en attente' })
  status!: string;
  
}