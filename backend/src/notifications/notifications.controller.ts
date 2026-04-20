// notifications.controller.ts
import { Controller, Get, Post, Body, Param, Patch } from '@nestjs/common';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationController {
  notificationsService: any;
  tasksService: any;
  constructor(private readonly service: NotificationsService) {}

  @Post()
  create(@Body() body: any) {
    return this.service.createNotification(body);
  }

  @Get(':email')
  find(@Param('email') email: string) {
    return this.service.findByCompany(email);
  }

  @Patch(':id/read')
  markAsRead(@Param('id') id: number) {
    return this.service.markAsRead(+id);
  }

 @Patch(':id/accept')
async accept(@Param('id') id: number) {
  const notif = await this.notificationsService.updateStatus(id, 'accepted');

  console.log("ACCEPT CALLED", notif); // 👈 debug

  await this.tasksService.create({
    message: notif.message,
    company: notif.receiver,
    status: 'accepted',
  });

  return notif;
}

@Patch(':id/reject')
async reject(@Param('id') id: number) {
  const notif = await this.notificationsService.updateStatus(id, 'rejected');

  console.log("REJECT CALLED", notif); // 👈 debug

  await this.tasksService.create({
    message: notif.message,
    company: notif.receiver,
    status: 'rejected',
  });

  return notif;
}
}