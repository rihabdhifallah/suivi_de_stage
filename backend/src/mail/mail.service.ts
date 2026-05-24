import { Injectable, Logger } from '@nestjs/common';
import { MailerService } from '@nestjs-modules/mailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(private readonly mailerService: MailerService) {}

  async sendCompanyMail(email: string, password: string) {
    try {
      console.log("👉 SENDING MAIL TO:", email);
      const res = await this.mailerService.sendMail({
        to: email,
        subject: 'Compte entreprise créé',
        text: `Bonjour,\n\nVotre compte entreprise a été créé avec succès.\n\nVos identifiants :\nEmail : ${email}\nMot de passe : ${password}\n\nMerci.`,
      });
      console.log("MAIL SENT SUCCESS");
      return res;
    } catch (err) {
      console.log("MAIL ERROR :", err);
      throw err;
    }
  }

  async sendStudentCredentials(email: string, nom: string, prenom: string, password: string) {
    try {
      console.log("👉 SENDING STUDENT CREDENTIALS TO:", email);
      const res = await this.mailerService.sendMail({
        to: email,
        subject: '🎓 Votre compte étudiant a été créé',
        text: `Bonjour ${prenom} ${nom},\n\nVotre compte étudiant a été créé avec succès par l'administrateur.\n\nVos identifiants de connexion :\n📧 Email : ${email}\n🔑 Mot de passe : ${password}\n\nVeuillez vous connecter et changer votre mot de passe dès que possible.\n\nCordialement,\nL'équipe pédagogique`,
      });
      console.log("STUDENT MAIL SENT SUCCESS");
      return res;
    } catch (err) {
      console.log("STUDENT MAIL ERROR :", err);
      throw err;
    }
  }

  async sendAcademicCredentials(email: string, nom: string, prenom: string, password: string) {
    try {
      console.log("👉 SENDING ACADEMIC CREDENTIALS TO:", email);
      const res = await this.mailerService.sendMail({
        to: email,
        subject: '💼 Votre compte encadrant académique a été créé',
        text: `Bonjour M./Mme. ${prenom} ${nom},\n\nVotre compte encadrant académique a été créé avec succès par l'administrateur.\n\nVos identifiants de connexion :\n📧 Email : ${email}\n🔑 Mot de passe : ${password}\n\nVeuillez vous connecter pour accéder à votre espace de suivi de stage.\n\nCordialement,\nL'administration`,
      });
      console.log("ACADEMIC MAIL SENT SUCCESS");
      return res;
    } catch (err) {
      console.log("ACADEMIC MAIL ERROR :", err);
      throw err;
    }
  }

  async sendProfessionalCredentials(email: string, nomComplet: string, password: string) {
    try {
      console.log("👉 SENDING PROFESSIONAL CREDENTIALS TO:", email);
      const res = await this.mailerService.sendMail({
        to: email,
        subject: '💼 Votre compte encadrant professionnel a été créé',
        text: `Bonjour ${nomComplet},\n\nVotre compte encadrant professionnel a été créé par l'entreprise.\n\nVos identifiants de connexion :\n📧 Email : ${email}\n🔑 Mot de passe : ${password}\n\nVeuillez vous connecter pour accéder à votre espace de suivi de stage.\n\nCordialement,\nL'équipe administrative`,
      });
      console.log("PROFESSIONAL MAIL SENT SUCCESS");
      return res;
    } catch (err) {
      console.log("PROFESSIONAL MAIL ERROR :", err);
      throw err;
    }
  }
}