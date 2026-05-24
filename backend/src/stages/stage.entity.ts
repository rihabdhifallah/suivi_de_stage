import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from "typeorm";
import { StageStatus } from "./stage-status.enum";
import { Application } from "src/applications/application.entity";

@Entity('stages')
export class Stage {

  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
titre!: string;

@Column()
domaine!: string;

@Column()
duree!: string;

  @Column({ nullable: true })
  niveau!: string;

  @Column({ nullable: true })
  places!: number;
@OneToMany(() => Application, (app) => app.stage)
applications!: Application[];
  @Column({ nullable: true })
  companyEmail!: string;
  @Column({ nullable: true })
  companyName!: string; 
  @Column({ nullable: true })
date!: string;

@Column({ nullable: true })
city!: string;

@Column("simple-array", { nullable: true })
skills!: string[];
  @Column({
    type: 'enum',
    enum: StageStatus,
    default: StageStatus.PENDING,
  })
  status!: StageStatus;

  @Column({
    type: 'enum',
    enum: ['company_offer', 'student_proposal', 'admin_created'],
    default: 'company_offer',
  })
  type!: 'company_offer' | 'student_proposal' | 'admin_created';

  @Column({ default: false })
  published!: boolean;

 @Column({ default: true })
active!: boolean;
}

export { StageStatus };
