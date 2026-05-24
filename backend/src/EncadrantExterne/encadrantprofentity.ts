import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from "typeorm";
import { Invitation } from "../invitation/invitation.entity";

@Entity()
export class EncadrantProfessionnel {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  nomComplet!: string;

  @Column()
  email!: string;

  @Column({ nullable: true })
  poste!: string;

  @Column({ nullable: true })
  adresse!: string;

  @Column({ nullable: true })
  telephone!: string;

  @Column({ nullable: true })
  companyId!: number;

  @OneToMany(() => Invitation, (inv) => inv.encadrant)
  invitations!: Invitation[];
}