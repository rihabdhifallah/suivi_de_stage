import { IsString, IsOptional } from 'class-validator';

export class CreateTaskDto {
  @IsString()
  titre!: string;

  @IsString()
  sender!: string; // 🔥 هذا كان ناقص

  @IsString()
  receiver!: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  fac_name?: string;

  @IsOptional()
  @IsString()
  fac_email?: string;

  @IsOptional()
  @IsString()
  fac_phone?: string;

  @IsOptional()
  @IsString()
  fac_pays?: string;

  @IsOptional()
  @IsString()
  message?: string;
}