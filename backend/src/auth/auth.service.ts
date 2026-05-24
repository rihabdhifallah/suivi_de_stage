import { Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { MailService } from 'src/mail/mail.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) 
    private readonly userRepository: Repository<User>,
    private readonly jwtService: JwtService,
    private readonly mailService: MailService,
  ) {}

async signup(body: any) {
  const hashedPassword = await bcrypt.hash(body.password, 10);

  const user = this.userRepository.create({
  name: body.name,
  email: body.email.toLowerCase().trim(),
  password: hashedPassword,

  role: body.role ?? 'student',

  niveau: body.niveau ?? '',
  universite: body.universite ?? '',
  specialite: body.specialite ?? '',
  phone: body.phone ?? '',
  country: body.country ?? '',

  poste: body.poste ?? '',
  entreprise: body.entreprise ?? '',

  status: 'active',
});

  return this.userRepository.save(user);
}
async login(email: string, password: string) {
  console.log('EMAIL:', email);
  console.log('PASSWORD:', password);
  const user = await this.userRepository.findOne({ where: { email } });

  if (!user) throw new UnauthorizedException('Email incorrect');

  if (user.status === 'archived') {
    throw new UnauthorizedException('Votre compte a été archivé. Connexion impossible.');
  }

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) throw new UnauthorizedException('Password incorrect');
return {
  access_token: this.jwtService.sign({
    sub: user.id,
    role: user.role,
    name: user.name,
    email: user.email,
    phone: user.phone,      
    country: user.country,   
  }),
    id: user.id, 

  role: user.role,
  name: user.name,
  email: user.email,
  phone: user.phone,
  country: user.country,
   niveau: user.niveau,
  universite: user.universite,
  specialite: user.specialite,

};}

  async forgotPassword(email: string): Promise<string> {
  const user = await this.userRepository.findOne({ where: { email } });
  if (!user) throw new Error('Email non trouvé');

  console.log(`Réinitialisation du mot de passe pour : ${email}`);
  return `Lien de réinitialisation envoyé à ${email}`;
}

async onModuleInit() {
    await this.createAdminIfNotExists();
  }

  async createAdminIfNotExists() {
    const adminEmail = 'admin@gmail.com';

    const exists = await this.userRepository.findOne({
      where: { email: adminEmail },
    });

    if (exists) return;

    const hashedPassword = await bcrypt.hash('admin123', 10);

    const admin = this.userRepository.create({
      name: 'Admin',
      email: adminEmail,
      password: hashedPassword,
      role: 'admin',
      status: 'active',
    });

    await this.userRepository.save(admin);
  }
  

  async getEncadrantsByCompany(companyId: number) {
    return this.userRepository.find({
      where: {
        role: 'encadrant',
        companyId: companyId,
      },
    });
  }

  async createStudent(body: any) {
    // Generate random 10-char password
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#';
    const randomPassword = Array.from({ length: 10 }, () =>
      chars[Math.floor(Math.random() * chars.length)]
    ).join('');

    const hashedPassword = await bcrypt.hash(randomPassword, 10);

    const user = this.userRepository.create({
      name: body.nom,
      prenom: body.prenom,
      email: body.email.toLowerCase().trim(),
      password: hashedPassword,
      role: 'student',
      cin: body.cin ?? '',
      adresse: body.adresse ?? '',
      dateNaissance: body.dateNaissance ?? '',
      genre: body.genre ?? '',
      niveau: body.niveau ?? '',
      specialite: body.specialite ?? '',
      departement: body.departement ?? '',
      universite: body.universite ?? '',
      phone: body.phone ?? '',
      status: 'active',
    });

    const saved = await this.userRepository.save(user);

    // Send credentials by email
    try {
      await this.mailService.sendStudentCredentials(
        body.email,
        body.nom,
        body.prenom,
        randomPassword,
      );
    } catch (e) {
      console.log('Email send failed (non-blocking):', e);
    }

    return { 
      message: 'Étudiant créé avec succès', 
      id: saved.id,
      email: body.email.toLowerCase().trim(),
      password: randomPassword
    };
  }

  async createAcademique(body: any) {
    // Generate random 10-char password
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#';
    const randomPassword = Array.from({ length: 10 }, () =>
      chars[Math.floor(Math.random() * chars.length)]
    ).join('');

    const hashedPassword = await bcrypt.hash(randomPassword, 10);

    const user = this.userRepository.create({
      name: body.nom,
      prenom: body.prenom,
      email: body.email.toLowerCase().trim(),
      password: hashedPassword,
      role: 'academique',
      cin: body.cin ?? '',
      etablissement: body.etablissement ?? '',
      departement: body.departement ?? '',
      specialite: body.specialite ?? '',
      phone: body.phone ?? '',
      status: 'active',
    });

    const saved = await this.userRepository.save(user);

    // Send credentials by email
    try {
      await this.mailService.sendAcademicCredentials(
        body.email,
        body.nom,
        body.prenom,
        randomPassword,
      );
    } catch (e) {
      console.log('Email send failed (non-blocking):', e);
    }

    return { 
      message: 'Encadrant académique créé avec succès', 
      id: saved.id,
      email: body.email.toLowerCase().trim(),
      password: randomPassword
    };
  }
}

