import { Invitation } from "../invitation/invitation.entity";
import { Entity, PrimaryGeneratedColumn, Column, OneToMany, OneToOne } from "typeorm";

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

 @Column({ nullable: true })
city!: string;

@Column({ nullable: true })
dateDebut!: string;

@Column({ nullable: true })
dateFin!: string;

@Column("simple-array", { nullable: true })
skills!: string[];

@Column({ default: true })
active!: boolean;


@Column({ default: "PENDING" })
status!: string;

@Column({ nullable: true })
typeStage!: string;

@Column({ nullable: true })
remuneration!: string;

@Column({ nullable: true })
companyName!: string;

@OneToMany(() => Invitation, (i) => i.offre)
invitations!: Invitation[];
}
