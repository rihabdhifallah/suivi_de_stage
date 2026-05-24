import { Presentation } from 'src/presentations/presentation.entity';
import { Rapport } from 'src/rapports/rapport.entity';
import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, OneToMany } from 'typeorm';

@Entity('users')
export class User {

  @PrimaryGeneratedColumn()
  id!: number; 
  
@Column()
name!: string;

@Column()
role!: string; 

  @Column({ nullable: true })
  email!: string;

  @Column({ nullable: true })
  password!: string;

  @Column({ default: 'pending' })
  status!: string;

  @Column({ nullable: true })
  niveau!: string;

  @Column({ nullable: true })
  universite!: string;

@Column({ nullable: true })
specialite!: string;

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

@Column({ nullable: true })
photo!: string;

@Column({ nullable: true })
companyId!: number;

@Column({ nullable: true })
prenom!: string;

@Column({ nullable: true })
cin!: string;

@Column({ nullable: true })
adresse!: string;

@Column({ nullable: true })
dateNaissance!: string;

@Column({ nullable: true })
genre!: string;

 @ManyToOne(() => User, (user) => user.studentsAsEncadrant, { nullable: true })
encadrant?: User;

@OneToMany(() => User, (user) => user.encadrant)
studentsAsEncadrant!: User[];

@OneToMany(() => Rapport, (rapport) => rapport.student)
rapports!: Rapport[];

@OneToMany(() => Rapport, (rapport) => rapport.encadrant)
encadrantRapports!: Rapport[];

@OneToMany(() => Presentation, (p) => p.student)
presentations!: Presentation[];

@OneToMany(() => Presentation, (p) => p.encadrant)
encadrantPresentations!: Presentation[];



}