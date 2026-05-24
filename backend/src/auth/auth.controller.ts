import {
  Controller,
  Post,
  Body,
  Get,
  Patch,
  Request,
  UnauthorizedException,
  UseGuards,
  Param,
  Query,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';

import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';

import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { AuthService } from './auth.service';
import { AuthGuard } from '@nestjs/passport';
import { StagesService } from 'src/stages/stages.service';
import { RegisterCompanyService } from './register-company/register-company.service';
import { Rapport } from 'src/rapports/rapport.entity';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly stagesService: StagesService,
    private readonly registerCompanyService: RegisterCompanyService,

    @InjectRepository(User)
    private readonly userRepository: Repository<User>,

    @InjectRepository(Rapport)
    private readonly rapportRepo: Repository<Rapport>,
  ) {}


  @Post('signup')
  signup(@Body() body: any) {
    return this.authService.signup(body);
  }

  @Post('login')
  login(@Body() body: any) {
    return this.authService.login(body.email, body.password);
  }

  @Post('forgot-password')
  forgotPassword(@Body() body: { email: string }) {
    return this.authService.forgotPassword(body.email);
  }

  @Get('check-email')
  async checkEmail(@Query('email') email: string) {
    const exists = await this.userRepository.findOne({
      where: { email: email.toLowerCase().trim() },
    });
    return { available: !exists };
  }



  @Post('register-company')
  register(@Body() body: any) {
    return this.registerCompanyService.register(body);
  }


  @UseGuards(AuthGuard('jwt'))
  @Get('profile')
  getProfile(@Request() req) {
    return this.userRepository.findOne({
      where: { id: req.user.userId },
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch('change-password')
  async changePassword(@Request() req, @Body() body: { currentPassword: string; newPassword: string }) {
    const user = await this.userRepository.findOne({ where: { id: req.user.userId } });
    if (!user) throw new UnauthorizedException('Utilisateur introuvable');

    const bcrypt = await import('bcrypt');
    const isMatch = await bcrypt.compare(body.currentPassword, user.password);
    if (!isMatch) throw new UnauthorizedException('Mot de passe actuel incorrect');

    const hashed = await bcrypt.hash(body.newPassword, 10);
    await this.userRepository.update(req.user.userId, { password: hashed });
    return { message: 'Mot de passe modifié avec succès' };
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch('profile')
  async updateProfile(@Request() req, @Body() body) {
    await this.userRepository.update(req.user.userId, {
      name: body.name,
      phone: body.phone,
      country: body.country,
      universite: body.universite,
      specialite: body.specialite,
      entreprise: body.entreprise,
      poste: body.poste,
    });

    return this.userRepository.findOne({
      where: { id: req.user.userId },
    });
  }


  @UseGuards(AuthGuard('jwt'))
  @Patch('admin/encadrants-pro/:id/archive')
  async archiveEncadrantPro(@Request() req, @Param('id') id: number) {
    if (!req.user || req.user.role !== 'admin') {
      throw new UnauthorizedException('Not admin');
    }
    const user = await this.userRepository.findOne({
      where: { id: Number(id), role: 'encadrant-professionnel' },
    });
    if (!user) throw new UnauthorizedException('Encadrant introuvable');
    const newStatus = user.status === 'archived' ? 'active' : 'archived';
    await this.userRepository.update(Number(id), { status: newStatus });
    return { status: newStatus };
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('admin/encadrants-pro')
  async getEncadrantsPro(@Request() req) {
    if (!req.user || req.user.role !== 'admin') {
      throw new UnauthorizedException('Not admin');
    }
    return this.userRepository.find({ where: { role: 'encadrant-professionnel' } });
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('admin/students')
  getStudents(@Request() req) {
    if (!req.user || req.user.role !== 'admin') {
      throw new UnauthorizedException('Not admin');
    }
    return this.userRepository.find({ where: { role: 'student' } });
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('admin/academiques')
  getAcademiques(@Request() req) {
    if (!req.user || req.user.role !== 'admin') {
      throw new UnauthorizedException('Not admin');
    }
    return this.userRepository.find({ where: { role: 'academique' } });
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch('admin/users/:id')
  async updateUser(@Request() req, @Param('id') id: number, @Body() body: any) {
    if (!req.user || req.user.role !== 'admin') {
      throw new UnauthorizedException('Not admin');
    }
    await this.userRepository.update(id, body);
    return this.userRepository.findOne({ where: { id: Number(id) } });
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch('admin/users/:id/archive')
  async archiveUser(@Request() req, @Param('id') id: number) {
    if (!req.user || req.user.role !== 'admin') {
      throw new UnauthorizedException('Not admin');
    }
    const user = await this.userRepository.findOne({ where: { id: Number(id) } });
    if (!user) throw new UnauthorizedException('User not found');
    const newStatus = user.status === 'archived' ? 'active' : 'archived';
    await this.userRepository.update(id, { status: newStatus });
    return { status: newStatus };
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('admin/create-student')
  async createStudent(@Request() req, @Body() body: any) {
    if (!req.user || req.user.role !== 'admin') {
      throw new UnauthorizedException('Not admin');
    }
    return this.authService.createStudent(body);
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('admin/create-academique')
  async createAcademique(@Request() req, @Body() body: any) {
    if (!req.user || req.user.role !== 'admin') {
      throw new UnauthorizedException('Not admin');
    }
    return this.authService.createAcademique(body);
  }

  @Get('company/:id/encadrants')
  getEncadrants(@Param('id') id: number) {
    return this.authService.getEncadrantsByCompany(id);
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('upload-photo')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads',
        filename: (req, file, cb) => {
          const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1e9);
          cb(null, uniqueName + extname(file.originalname));
        },
      }),
    }),
  )
  async uploadPhoto(@Request() req, @UploadedFile() file: any) {
    if (!file) {
      throw new Error("No file uploaded");
    }
    await this.userRepository.update(req.user.userId, {
      photo: file.filename,
    });
    return { photo: file.filename };
  }
}