import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('companies')
export class Company {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  nom!: string;

  @Column()
  email!: string;

  @Column()
  telephone!: string;

  @Column()
  pays!: string;
}