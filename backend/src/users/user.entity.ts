import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users')
export class User {

  @PrimaryGeneratedColumn()
  id!: number; // ✅

  @Column()
  role!: string; // ✅

  @Column({ nullable: true })
  email!: string;

  @Column({ nullable: true })
  name!: string;

  @Column({ nullable: true })
  password!: string;

  @Column({ default: 'pending' })
  status!: string;

  @Column({ nullable: true })
  niveau!: string;

  @Column({ nullable: true })
  universite!: string;

  @Column({ nullable: true })
  departement!: string;

  @Column({ nullable: true })
  etablissement!: string;

  @Column({ nullable: true })
  poste!: string;

  @Column({ nullable: true })
  entreprise!: string;
 @Column({ nullable: true })
phone!: string;

@Column({ nullable: true })
country!: string;
  
}