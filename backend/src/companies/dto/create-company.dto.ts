import { IsString, IsEmail } from 'class-validator';

export class CreateCompanyDto {
  @IsString()
  nom!: string;

  @IsEmail()
  email!: string;

  @IsString()
  secteurActivite!: string;

  @IsString()
  adresse!: string;

  @IsString()
  telephone!: string;
}