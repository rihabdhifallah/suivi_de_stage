import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CompaniesModule } from './companies/companies.module';
import { OffreModule } from './offre/offermodule';
import { StagesModule } from './stages/stages.module';
import { MailerModule } from '@nestjs-modules/mailer';
import { MailModule } from './mail/mail.module';
import { ApplicationModule } from './applications/application.module';
import { JournalModule } from './journal/journal.module';
import { RapportsModule } from './rapports/rapports.module';
import { DemandesModule } from './demandes/demandes.module';
import { EncadrantModule } from './encadrant/encadrant.module';
import { EncadrementModule } from './encadrement/encadrement.module';
import { join } from 'path';
import { ServeStaticModule } from '@nestjs/serve-static';
import { PresentationsModule } from './presentations/presentations.module';
import { Convention } from './convention/convention.entity';
import { ConventionModule } from './convention/convention.module';
import { EncadrantProfessionnelModule } from './EncadrantExterne/Encadrantpro.module';
import { InvitationModule } from './invitation/invitation.module';
import { SpecialitesModule } from './specialites/specialites.module';
import { DepartementsModule } from './departements/departements.module';
import { TaskModule } from './task/task.module';
import { NotificationModule } from './notifications/notifications.module';
import { ReunionsModule } from './reunions/reunions.module';

import { MessagesModule } from './messages/messages.module';

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
  ServeStaticModule.forRoot({
      rootPath: join(process.cwd(), 'uploads'),
      serveRoot: '/uploads',
    }),
    AuthModule,
    StagesModule,
    UsersModule,
    CompaniesModule,
    OffreModule,
    ApplicationModule,
    JournalModule,
    DemandesModule,
    EncadrantModule,
    MailModule,
    EncadrementModule,
    RapportsModule,
    PresentationsModule,
    ConventionModule , 
    EncadrantProfessionnelModule,
    InvitationModule,
    SpecialitesModule,
    DepartementsModule,
    TaskModule,
    NotificationModule,
    ReunionsModule,
    MessagesModule,
  ],
})
export class AppModule {}