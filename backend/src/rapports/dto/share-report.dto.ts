import { Type } from 'class-transformer';
import { IsEmail, IsNumber } from 'class-validator';

export class ShareReportDto {

  @Type(() => Number)
  @IsNumber()
  rapportId!: number;

  @IsEmail()
  email!: string;
}