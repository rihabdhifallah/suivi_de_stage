import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from "typeorm";

@Entity()
export class Journal {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  studentId!: number;

  @Column({ nullable: true })
  mood!: string;

@Column({ nullable: false, default: "" })
title!: string;
  @Column({ type: "text", nullable: true })
  tasksDone!: string;

  @Column({ type: "text", nullable: true })
  tasksInProgress!: string;

 @Column({ type: "json", nullable: true, default: [] })
difficulties!: any;

  @Column({ nullable: true })
  severity!: string;

  @Column({ type: "text", nullable: true })
  solution!: string;

  @Column({ type: "text", nullable: true })
  learned!: string;

  @Column({ type: "text", nullable: true })
  plan!: string;

  @Column({ type: "json", nullable: true })
tags!: any;
  @CreateDateColumn()
  createdAt!: Date;
}