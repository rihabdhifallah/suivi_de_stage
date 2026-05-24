import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Request,
  UseGuards,
} from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { JournalService } from "./journal.service";
import { CreateJournalDto } from "./dto/create-journal.dto";

@UseGuards(AuthGuard("jwt"))
@Controller("journal")
export class JournalController {
  constructor(private service: JournalService) {}
@Post()
create(@Request() req, @Body() dto: CreateJournalDto) {
  console.log(" JOURNAL HIT");
  console.log("USER:", req.user);
  console.log("DTO:", dto);

  return this.service.create(req.user.userId, dto);
}

  @Get("me")
  findMine(@Request() req) {
    return this.service.findByStudent(req.user.userId);
  }

  @Get(":id")
  findOne(@Param("id") id: number) {
    return this.service.findOne(id);
  }

  @Delete(":id")
remove(@Param("id") id: number) {
  return this.service.delete(id);
}
  
}