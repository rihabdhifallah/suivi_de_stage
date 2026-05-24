import { IsString, IsNotEmpty } from "class-validator";

export class CreatePresentationDto {
  @IsString()
  @IsNotEmpty()
  titre?: string;

  @IsString()
  @IsNotEmpty()
  type?: string;

  @IsString()
  @IsNotEmpty()
  date?: string;
}