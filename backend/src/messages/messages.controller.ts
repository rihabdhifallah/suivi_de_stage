import { Body, Controller, Get, Param, Post, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { MessagesService } from './messages.service';

@Controller('messages')
@UseGuards(AuthGuard('jwt'))
export class MessagesController {
  constructor(private svc: MessagesService) {}

  /** Envoyer un message */
  @Post('send')
  send(@Request() req: any, @Body() body: { receiverEmail: string; content: string }) {
    return this.svc.send(req.user.email, body.receiverEmail, body.content);
  }

  /** Conversation avec un autre utilisateur */
  @Get('conversation/:otherEmail')
  getConversation(@Request() req: any, @Param('otherEmail') other: string) {
    return this.svc.getConversation(req.user.email, other);
  }

  /** Liste des conversations */
  @Get('conversations')
  getConversations(@Request() req: any) {
    return this.svc.getConversationList(req.user.email);
  }

  /** Nombre de messages non lus */
  @Get('unread-count')
  unreadCount(@Request() req: any) {
    return this.svc.countUnread(req.user.email);
  }
}
