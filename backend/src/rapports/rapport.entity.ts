import { User } from 'src/users/user.entity';
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';

@Entity()
export class Rapport {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ nullable: true })
  title!: string;

  @Column({ nullable: true })
  type!: string;

  @Column({ nullable: true })
  resume!: string;

  @Column({ nullable: true })
  difficulty!: string;

  @Column({ nullable: true })
  company!: string;

  @Column({ nullable: true })
  periode!: string;

  @Column({ nullable: true })
  file!: string;

  @ManyToOne(() => User, (user) => user.rapports)
  student!: User;

  @ManyToOne(() => User, (user) => user.encadrantRapports, { nullable: true })
  encadrant?: User;
@Column({ nullable: true })
status!: string; 
// en_revision | valide | refuse

@Column({ type: 'text', nullable: true })
commentaire!: string;
  @CreateDateColumn()
  createdAt!: Date;
}