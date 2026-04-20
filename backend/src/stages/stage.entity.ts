import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";
import { StageStatus } from "./stage-status.enum";

@Entity('stages')
export class Stage {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  title!: string;

  @Column()
  company!: string;

  @Column()
  subject!: string;

  @Column({ nullable: true })
  startDate!: string;

  @Column({ nullable: true })
  endDate!: string;

  @Column({ nullable: true })
  niveau!: string;

  @Column({ nullable: true })
  places!: number;

  @Column({ type: 'enum', enum: StageStatus, default: StageStatus.PENDING })
  status!: StageStatus;

  @Column()
  type!: 'company_offer' | 'student_proposal' | 'admin_created';
  published!: boolean;
}