import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PassportModule } from '@nestjs/passport';
import { JwtModule } from '@nestjs/jwt';

import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { User } from '../users/user.entity';
import { JwtStrategy } from './jwt.strategy'; // 
import { StagesModule } from 'src/stages/stages.module';
import { Rapport } from 'src/rapports/rapport.entity';
import { RegisterCompanyController } from './register-company/register-company.controller';
import { RegisterCompanyService } from './register-company/register-company.service';
import { MailModule } from 'src/mail/mail.module';

@Module({
 imports: [
  TypeOrmModule.forFeature([User, Rapport]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
  JwtModule.register({
    secret: 'SECRET_KEY',
    signOptions: { expiresIn: '1d' },
  }),

  StagesModule,
  MailModule, // 
],
  controllers: [AuthController,RegisterCompanyController],
  providers: [AuthService, JwtStrategy,RegisterCompanyService,], 
})
export class AuthModule {}