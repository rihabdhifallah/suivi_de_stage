import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('companies')
export class Company {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  nom!: string;

 @Column({ unique: true })
email!: string;
  @Column()
  secteurActivite!: string;

  @Column()
  adresse!: string;

  @Column()
  telephone!: string;

 @Column()
password!: string;

@Column()
role!: string;

@Column({ default: 'active' })
status!: string;
}