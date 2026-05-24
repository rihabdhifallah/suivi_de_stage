import { Offre } from "src/offre/offre.entity";
import { Stage } from "src/stages/stage.entity";
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from "typeorm";

@Entity()
export class Application {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  studentId!: number;

  @Column()
  motivation!: string;

  @Column()
  phone!: string;

  @Column()
  niveau!: string;

  @Column({ nullable: true })
  note!: string;
 @Column({ nullable: true })
city!: string;

@Column({ nullable: true })
date!: string;
  @Column({ nullable: true })
  cv!: string;
@Column({ nullable: true })
companyEmail!: string;
  @Column({ nullable: true })
  studentEmail!: string;    // 
  @Column({ nullable: true })
  studentName!: string;     
@Column({ nullable: true })
etablissement!: string;

@Column({ nullable: true })
duree!: string;
@Column({ type: "text", nullable: true })
signatureCompany!: string;

@Column({ type: "text", nullable: true })
signatureStudent!: string;
@ManyToOne(() => Offre, { nullable: true })
offre!: Offre;

@ManyToOne(() => Stage, (stage) => stage.applications, {
  eager: true,   //    
})
@JoinColumn({ name: "stageId" })
stage!: Stage;

  @Column({ nullable: true })
  typeStage!: string;

  @Column({ default: "pending" })
  status!: string;
}