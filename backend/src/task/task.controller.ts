import { Controller, Get, Post, Body, Param, Patch } from '@nestjs/common';
import { TaskService } from './task.service';
import { CreateTaskDto } from './dto/create-task.dto';

@Controller('tasks')
export class TaskController {
  constructor(private readonly taskService: TaskService) {}

  

  //  GET ALL
  @Get()
  findAll() {
    return this.taskService.findAll();
  }
  @Post()
  create(@Body() dto: CreateTaskDto) {
    console.log("DTO RECEIVED =>", dto);
    return this.taskService.create(dto);
  }

  @Get('receiver/:email')
  findByReceiver(@Param('email') email: string) {
    return this.taskService.findByReceiver(email);
  }

  @Get('sender/:email')
  findBySender(@Param('email') email: string) {
    return this.taskService.findBySender(email);
  }

  @Patch(':id/status')
  updateStatus(
    @Param('id') id: string,
    @Body('status') status: string,
    @Body('comment') comment?: string,
  ) {
    return this.taskService.updateStatus(+id, status, comment);
  }
}