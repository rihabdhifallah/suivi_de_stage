import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
} from "typeorm";
import { User } from "../users/user.entity";

@Entity()
export class Presentation {

  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  titre!: string;

  @Column()
  type!: string;

  @Column({ type: "date" })
  date!: string;

  @Column()
  file!: string;

  @Column({ default: "en_attente" })
  status!: string;

  @Column({ nullable: true })
  comment?: string;

  @ManyToOne(() => User, (u) => u.presentations)
  student!: User;

  @ManyToOne(() => User, (u) => u.encadrantPresentations)
  encadrant!: User;

  @Column()
  encadrantName!: string;

  @Column()
  encadrantEmail!: string;

  @Column()
  encadrantEtablissement!: string;

  @CreateDateColumn()
  createdAt!: Date;
}