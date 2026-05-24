import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  UploadedFile,
  UseInterceptors,
  UseGuards,
  Request,
  Patch
} from '@nestjs/common';

import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { RapportsService } from './rapports.service';
import { AuthGuard } from '@nestjs/passport';
import { ShareReportDto } from './dto/share-report.dto';

@UseGuards(AuthGuard("jwt"))
@Controller('rapports')
export class RapportsController {
  rapportsService: any;
  constructor(private service: RapportsService) {}

  @Post()
  @UseInterceptors(
    FileInterceptor('pdf', {
      storage: diskStorage({
        destination: './uploads/rapports',
        filename: (req, file, cb) => {
          const unique = Date.now() + '-' + file.originalname;
          cb(null, unique);
        },
      }),
    }),
  )
  create(
    @Body() body: any,
    @UploadedFile() file: Express.Multer.File,
    @Request() req,
  ) {
    return this.service.create(body, file, req.user.userId);
  }

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get('me')
  findMine(@Request() req) {
    return this.service.findByUser(req.user.userId);
  }

  @Get('user/:id')
  findByUser(@Param('id') id: number) {
    return this.service.findByUser(id);
  }
@Patch(':id/review')
review(@Param('id') id: number, @Body() dto: any) {
  return this.service.reviewRapport(id, dto);
}
@Post('share')
share(@Body() dto: ShareReportDto) {
  console.log('DTO RECEIVED:', dto);
  return this.service.shareReport(dto.rapportId, dto.email);
}
@Post('comment')
addComment(@Body() dto: any) {
  return this.service.addComment(dto.reportId, dto.comment);
}
@Get(':id')
findOne(@Param('id') id: number) {
  return this.service.findOne(+id);
}
  @Delete(':id')
  remove(@Param('id') id: number) {
    return this.service.remove(id);
  }

  @Get('encadrant/me')
  getMyEncadrantReports(@Request() req) {
    return this.service.findByEncadrant(req.user.userId);
  }
  
}