import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PassportModule } from '@nestjs/passport';
import { JwtModule } from '@nestjs/jwt';

import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { User } from '../users/user.entity';
import { JwtStrategy } from './jwt.strategy'; // 
import { StageModule } from 'src/stages/stage.module';
import { Journal } from 'src/journal/journal.entity';
import { Rapport } from 'src/rapport/rapport.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Journal, Rapport]), //
    PassportModule,
    JwtModule.register({
      secret: 'SECRET_KEY',
      signOptions: { expiresIn: '1d' },
    }),
        StageModule, // 
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy], 
})
export class AuthModule {}