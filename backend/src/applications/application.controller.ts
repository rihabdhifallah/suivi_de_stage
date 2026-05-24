import {
  Controller,
  Post,
  UseInterceptors,
  UploadedFiles,
  Body,
  Param,
  UseGuards,
  Request,
  Get,
} from "@nestjs/common";

import { FileFieldsInterceptor } from "@nestjs/platform-express";
import { diskStorage } from "multer";
import { extname } from "path";
import { AuthGuard } from "@nestjs/passport";
import { ApplicationService } from "./application.service";
@Controller("applications")
export class ApplicationController {
  constructor(private service: ApplicationService) {}

  // ================= APPLY (FULL VERSION) =================
 @UseGuards(AuthGuard("jwt"))
@Post("apply/:stageId")
@UseInterceptors(
  FileFieldsInterceptor(
    [
      { name: "cv", maxCount: 1 },
      { name: "motivation", maxCount: 1 },
    ],
    {
      storage: diskStorage({
        destination: "./uploads",
        filename: (req, file, cb) => {
          const uniqueName =
            Date.now() + "-" + Math.round(Math.random() * 1e9);
          cb(null, uniqueName + extname(file.originalname));
        },
      }),
    }
  ),
)
async apply(
  @UploadedFiles() files: { cv?: Express.Multer.File[], motivation?: Express.Multer.File[] },
  @Body() body: any,
  @Param("stageId") stageId: number,
  @Request() req,
) {
    console.log("ENTER APPLY"); 

  console.log("AUTH HEADER ", req.headers.authorization); 
  console.log("USER =>", req.user);

try {
  return await this.service.apply({
    studentId: req.user.userId,
    studentEmail: req.user.email,
    studentName: req.user.name || req.user.email,
    stageId: Number(stageId),
    companyEmail: body.companyEmail,
    motivation: files?.motivation?.[0]?.filename || body.motivation,
    phone: body.phone,
    niveau: body.niveau,
    city: body.city,
    date: body.date,
    etablissement: body.etablissement,
    duree: body.duree,
    note: body.note,
    cv: files?.cv?.[0]?.filename,
    typeStage: body.typeStage,
  });
} catch (error: any) {
  console.error("APPLY ERROR:", error);
  throw error;
}
}

  // ================= MY APPLICATIONS =================
  @UseGuards(AuthGuard("jwt"))
  @Get("me")
  myApps(@Request() req) {
      console.log(req.user);
    return this.service.findByStudent(req.user.userId);
  }
  @Get("check-places/:stageId")
  async checkPlaces(@Param("stageId") stageId: number) {
    return this.service.checkPlaces(Number(stageId));
  }

    @Get("test")
  test() {
    return "API WORKS";
  }
@UseGuards(AuthGuard('jwt'))
@Get("debug")
debug(@Request() req) {
  console.log(" AUTH HEADER:", req.headers.authorization);
  console.log(" USER:", req.user);
  return "ok";
}
@Get('company/:email')
findByCompany(@Param('email') email: string) {
  console.log(" COMPANY HIT:", email);
  return this.service.findByCompany(email);
}

@Get('encadrant/:email')
findByEncadrant(@Param('email') email: string) {
  return this.service.findByEncadrant(email);
}
@Post(':id/sign-company')
signCompany(@Param('id') id: number, @Body() body) {
  return this.service.signCompany(id, body);
}

@Post(':id/sign-student')
signStudent(@Param('id') id: number, @Body() body) {
  return this.service.signStudent(id, body);
}

@Post(':id/accept')
accept(@Param('id') id: number) {
  return this.service.accept(id);
}

@Post(':id/refuse')
refuse(@Param('id') id: number) {
  return this.service.refuse(id);
}
}