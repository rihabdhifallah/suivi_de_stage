import { IsString } from 'class-validator';

export class CreateEncadrementDto {
  @IsString()
  annee?: string;

  @IsString()
  encadrant?: string;

  @IsString()
  emailEncadrant?: string;

  @IsString()
  niveau?: string;

  @IsString()
  specialite?: string;

  @IsString()
  emailEtudiant?: string;
}