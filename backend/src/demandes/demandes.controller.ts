import { Controller, Get, Post, Body, Put, Param, Patch, UseInterceptors, UploadedFiles, Res } from '@nestjs/common';
import { DemandesService } from './demandes.service';
import { CreateDemandeDto } from './dto/create-demande.dto';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import express from 'express'; //

@Controller('demandes')
export class DemandesController {
  demandeService: any;
  constructor(private service: DemandesService) {}
@Post()
@UseInterceptors(
  FileFieldsInterceptor(
    [
      { name: 'cv', maxCount: 1 },
      { name: 'lettre', maxCount: 1 },
    ],
    {
      storage: diskStorage({
        destination: './uploads',
        filename: (req, file, cb) => {
          cb(null, Date.now() + '-' + file.originalname);
        },
      }),
    },
  ),
)
async create(
  @Body() body: any,
  @UploadedFiles() files: any,
) {
  console.log("BODY =>", body);
  console.log("FILES =>", files);

  return this.service.create(body, files);
}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get('student/:id')
  findStudent(@Param('id') id: number) {
    return this.service.findByStudent(id);
  }

  

 @Get('file/:filename')
getFile(@Param('filename') filename: string, @Res() res: express.Response) {
  return res.sendFile(filename, { root: './uploads' });
}
@Put(':id/status')
updateStatus(
  @Param('id') id: number,
  @Body() body: { status: string }
) {
  return this.demandeService.updateStatus(id, body.status);
}
@Patch(':id/accept')
accept(@Param('id') id: number) {
  return this.service.updateStatus(id, 'accepted');
}
@Patch(':id/reject')
reject(@Param('id') id: number) {
  return this.service.updateStatus(id, 'rejected');
}
}