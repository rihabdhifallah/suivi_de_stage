import {
  Controller,
  Post,
  Body,
  Param,
  Get,
  Patch,
  Request,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';

import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';

import { AuthService } from './auth.service';
import { StageService } from 'src/stages/stage.service';
import { StageStatus } from 'src/stages/stage-status.enum';

import { Journal } from '../journal/journal.entity';
import { Rapport } from '../rapport/rapport.entity';

import * as bcrypt from 'bcrypt';
import { AuthGuard } from '@nestjs/passport';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly stageService: StageService,

    @InjectRepository(User)
    private readonly userRepository: Repository<User>,

    @InjectRepository(Journal)
    private readonly journalRepo: Repository<Journal>,

    @InjectRepository(Rapport)
    private readonly rapportRepo: Repository<Rapport>,
  ) {}

  // ================= AUTH =================

  @Post('signup')
  signup(@Body() body: Partial<User>) {
    return this.authService.signup(body);
  }

  @Post('login')
  login(@Body() body: { email: string; password: string }) {
    return this.authService.login(body.email, body.password);
  }

  @Post('forgot-password')
  forgotPassword(@Body() body: { email: string }) {
    return this.authService.forgotPassword(body.email);
  }



 @UseGuards(AuthGuard('jwt'))


  // ================= CHANGE PASSWORD =================

  @UseGuards(AuthGuard('jwt'))
  @Patch('change-password')
  async changePassword(@Request() req, @Body() body) {
    const user = await this.userRepository.findOneBy({
      id: req.user.sub,
    });

    if (!user) throw new UnauthorizedException();

    const match = await bcrypt.compare(
      body.oldPassword,
      user.password,
    );

    if (!match) {
      throw new UnauthorizedException('Old password incorrect');
    }

    user.password = await bcrypt.hash(body.newPassword, 10);

    await this.userRepository.save(user);

    return { message: 'Password updated successfully' };
  }

  // ================= JOURNAL =================

  @Post('journal')
  createJournal(@Body() body: any) {
    return this.journalRepo.save(body);
  }

  @Get('journal/:studentId')
  getJournal(@Param('studentId') id: string) {
    return this.journalRepo.find({
      where: { studentId: Number(id) },
    });
  }

  // ================= RAPPORT =================

  @Post('rapport')
  uploadRapport(@Body() body: any) {
    return this.rapportRepo.save(body);
  }

  // ================= STAGE =================

  @Post('company')
  createCompanyStage(@Body() body: any) {
    return this.stageService.createCompanyStage(body);
  }

  @Patch('accept/:id')
  accept(@Param('id') id: string) {
    return this.stageService.updateStatus(
      Number(id),
      StageStatus.ACCEPTED,
    );
  }

  @Patch('reject/:id')
  reject(@Param('id') id: string) {
    return this.stageService.updateStatus(
      Number(id),
      StageStatus.REJECTED,
    );
  }

  @Get('stages')
  findAll() {
    return this.stageService.findAll();
  }

  @UseGuards(AuthGuard('jwt'))
@Get('profile')
getProfile(@Request() req) {
    console.log("USER =>", req.user); // 

  return this.userRepository.findOne({
    where: { id: req.user.userId }, // 
  });
}

@UseGuards(AuthGuard('jwt'))
@Patch('profile')
async updateProfile(@Request() req, @Body() body) {

  console.log("USER =>", req.user); // 

  await this.userRepository.update(req.user.userId, {
    name: body.name,
    phone: body.phone,
    country: body.country,
  });

  return this.userRepository.findOne({
    where: { id: req.user.userId },
  });
}
}