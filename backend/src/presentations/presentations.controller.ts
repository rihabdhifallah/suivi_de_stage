import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
  UseInterceptors,
  UploadedFile,
  Req,
  UseGuards,
} from "@nestjs/common";
import { diskStorage } from "multer";
import { FileInterceptor } from "@nestjs/platform-express";
import { PresentationsService } from "./presentations.service";
import { JwtAuthGuard } from "src/auth/jwt-auth.guard";

@Controller("presentations")
@UseGuards(JwtAuthGuard)
export class PresentationsController {
  constructor(private service: PresentationsService) {}

  @Post()
  @UseInterceptors(
    FileInterceptor("file", {
      storage: diskStorage({
        destination: "./uploads",
        filename: (req, file, cb) => {
          const unique = Date.now() + "-" + file.originalname;
          cb(null, unique);
        },
      }),
    }),
  )
  create(@UploadedFile() file, @Body() dto, @Req() req) {
    return this.service.create(dto, file, req.user);
  }

  @Get("student")
getForStudent(@Req() req) {
  return this.service.findByStudent(req.user.userId || req.user.sub);
}

  @Get("my")
  getForMy(@Req() req) {
    return this.service.findByStudent(req.user.userId || req.user.sub);
  }

@Get("encadrant")
getForEncadrant(@Req() req) {
  return this.service.findByEncadrant(req.user.userId || req.user.sub);
}

@Patch(":id/review")
review(@Param("id") id: string, @Body() dto: { status?: string; comment?: string }) {
  return this.service.review(Number(id), dto);
}
}