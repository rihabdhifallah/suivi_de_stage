import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('conventions')
export class Convention {

  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  companyName!: string;

  @Column()
  title!: string;

  @Column()
  description!: string;

  @Column()
  fileUrl!: string;

  @Column({ default: 'pending' })
  status!: string; // pending | accepted | rejected
}