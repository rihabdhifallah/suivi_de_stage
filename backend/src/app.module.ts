import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthModule } from './auth/auth.module';
import { StageModule } from './stages/stage.module';
import { UsersModule } from './users/users.module';
import { CompaniesModule } from './companies/companies.module';
import { NotificationsModule } from './notifications/notifications.module';
import { TaskModule } from './task/task.module';
import { OffreModule } from './offre/offermodule';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: 'localhost',
      port: 5432,
      username: 'nestuser',
      password: '123456',
      database: 'suivi_stage',
      autoLoadEntities: true,
      synchronize: true,
    }),
    

    AuthModule,
    StageModule,
    UsersModule,
    CompaniesModule,
NotificationsModule,
    TaskModule,
    OffreModule, //

  ],
})
export class AppModule {}