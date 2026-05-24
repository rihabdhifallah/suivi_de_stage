import { Injectable } from "@nestjs/common";
import { MailerService } from "@nestjs-modules/mailer";
import * as bcrypt from "bcrypt";
import { MailService } from "src/mail/mail.service";

@Injectable()
export class RegisterCompanyService {

  constructor(private mailService: MailService) {}

  async register(body: any) {

    const plainPassword = Math.random().toString(36).slice(-8);

    const hashed = await bcrypt.hash(plainPassword, 10);

    const user = {
      name: body.name,
      email: body.email,
      password: hashed,
      role: "entreprise"
    };

    console.log("USER CREATED:", user);

    // 📧 correct usage
    await this.mailService.sendCompanyMail(
      body.email,
      plainPassword
    );

    return {
      message: "Company created + email sent",
    };
  }
}