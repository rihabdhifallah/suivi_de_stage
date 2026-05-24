import { Controller, Get, Post, Patch, Param, Delete, Req, Body, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { NotificationService } from "./notifications.service";

@Controller("notifications")
@UseGuards(AuthGuard("jwt"))
export class NotificationController {
  constructor(private service: NotificationService) {}

  // 📥 GET MY NOTIFICATIONS
  @Get()
  getMy(@Req() req) {
    return this.service.findMyNotifications(req.user.id);
  }

  // 🔢 UNREAD COUNT
  @Get("unread-count")
  unread(@Req() req) {
    return this.service.countUnread(req.user.id);
  }

  // ✉ SEND NOTIFICATION
  @Post()
  send(@Body() body: { recipientId: number; title: string; message: string; type?: string }) {
    return this.service.create(
      body.recipientId,
      body.type || "comment",
      body.title,
      body.message,
    );
  }

  // 👁 MARK AS READ
  @Patch(":id/read")
  read(@Param("id") id: number) {
    return this.service.markAsRead(id);
  }

  // 🗑 DELETE
  @Delete(":id")
  remove(@Param("id") id: number) {
    return this.service.delete(id);
  }
}