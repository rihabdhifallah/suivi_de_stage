import { Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) 
    private readonly userRepository: Repository<User>, // 
    private readonly jwtService: JwtService
  ) {}

 async signup(body: any) {
  const hashedPassword = await bcrypt.hash(body.password, 10);

  const user = this.userRepository.create({
    name: body.name,
    email: body.email,
    password: hashedPassword,
    role: body.role,
    phone: body.phone,
    country: body.country,
    status: 'active',
  });

  return this.userRepository.save(user);
}

async login(email: string, password: string) {
  const user = await this.userRepository.findOne({ where: { email } });

  if (!user) throw new UnauthorizedException('Email incorrect');

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
  role: user.role,
  name: user.name,
  email: user.email,
  phone: user.phone,
  country: user.country,
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
}
