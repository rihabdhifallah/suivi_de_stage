import { Body, Controller, Post } from "@nestjs/common";
import { RegisterCompanyService } from "./register-company.service";

@Controller('auth')
export class RegisterCompanyController {

  constructor(private readonly service: RegisterCompanyService) {}

  @Post('register-company')
  register(@Body() body: any) {
    return this.service.register(body);
  }
}