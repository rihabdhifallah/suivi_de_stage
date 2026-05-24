import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { existsSync, mkdirSync } from 'fs';
import { join } from 'path';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import * as express from 'express';
import { exec } from 'child_process';
import 'dotenv/config';

const PORT = 3001;

// Kills any process listening on the given port (Windows)
function killPort(port: number): Promise<void> {
  return new Promise((resolve) => {
    exec(`netstat -ano | findstr :${port}`, (_err, stdout) => {
      if (!stdout || !stdout.trim()) return resolve();

      const pids = new Set<string>();
      for (const line of stdout.trim().split('\n')) {
        if (line.includes('LISTENING')) {
          const parts = line.trim().split(/\s+/);
          const pid = parts[parts.length - 1];
          if (pid && pid !== '0') pids.add(pid);
        }
      }

      if (pids.size === 0) return resolve();

      const kills = [...pids].map(
        (pid) =>
          new Promise<void>((res) => exec(`taskkill /F /PID ${pid}`, () => res())),
      );

      Promise.all(kills).then(() => setTimeout(resolve, 600));
    });
  });
}

async function bootstrap() {
  console.log(`Freeing port ${PORT}...`);
  await killPort(PORT);
  console.log(`Port ${PORT} ready.`);

  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  console.log('EMAIL USER:', process.env.EMAIL_USER);
  console.log('EMAIL PASS:', process.env.EMAIL_PASS);

  app.enableCors();

  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );

  const uploadDir = join(__dirname, '..', 'uploads', 'rapports');
  if (!existsSync(uploadDir)) {
    mkdirSync(uploadDir, { recursive: true });
  }

  process.on('unhandledRejection', (reason) => {
    console.error('UNHANDLED REJECTION:', reason);
  });

  process.on('uncaughtException', (err) => {
    console.error('UNCAUGHT EXCEPTION:', err);
  });

  app.useStaticAssets(join(__dirname, '..', 'uploads'), {
    prefix: '/uploads/',
  });

  await app.listen(PORT, '0.0.0.0');
}

bootstrap();