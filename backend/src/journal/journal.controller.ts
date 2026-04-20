import { Controller, Post, Body, Param, Get } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Journal } from './journal.entity';

@Controller('journal')
export class JournalController {
  constructor(
    @InjectRepository(Journal)
    private readonly journalRepo: Repository<Journal>,
  ) {}

  @Post()
  create(@Body() body: any) {
    return this.journalRepo.save(body);
  }

  @Get(':studentId')
  find(@Param('studentId') id: number) {
    return this.journalRepo.find({
      where: { studentId: id },
    });
  }
}