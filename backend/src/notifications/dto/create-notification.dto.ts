export class CreateNotificationDto {
  userId?: number;
  type?: string;
  title?: string;
  message?: string;
  entityId?: number;
}