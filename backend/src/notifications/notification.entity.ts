import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
} from "typeorm";
import { User } from "../users/user.entity";

@Entity()
export class Notification {

  @PrimaryGeneratedColumn()
  id!: number;

  @ManyToOne(() => User)
  user!: User; // recipient (student)

  @Column({ default: "comment" })
  type!: string; // comment | demande | accept | refuse | rapport
  @Column({ default: "Notification" })
  title!: string;
  @Column({ default: "" })
  message!: string;

  @Column({ default: false })
  read!: boolean;
 @Column({ nullable: true })
  entityId!: number; 
  // id rapport / demande / etc (optional)

  @CreateDateColumn()
  createdAt!: Date;
}