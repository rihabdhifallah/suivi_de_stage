import {
  Entity,
  PrimaryGeneratedColumn,
  ManyToOne,
  Column,
  CreateDateColumn,
} from "typeorm";

import { Offre } from "../offre/offre.entity";
import { EncadrantProfessionnel } from "../EncadrantExterne/encadrantprofentity";

@Entity()
export class Invitation {
  @PrimaryGeneratedColumn()
  id!: number;

  @ManyToOne(() => EncadrantProfessionnel, (e) => e.invitations, {
    onDelete: "CASCADE",
    eager: true,   
  })
  encadrant!: EncadrantProfessionnel;

  @ManyToOne(() => Offre, (o) => o.invitations, {
    onDelete: "CASCADE",
  })
  offre!: Offre;

  @Column({ default: "pending" })
  status!: string;

  @CreateDateColumn()
  createdAt!: Date;
}