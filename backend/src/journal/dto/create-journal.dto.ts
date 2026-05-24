import { IsOptional } from "class-validator";

export class CreateJournalDto {
  mood?: string;
  title?: string;
  tasksDone?: string;
  learned?: string;
  solution?: string;
  plan?: string;
  severity?: string;

  @IsOptional()
  difficulties?: any;
}