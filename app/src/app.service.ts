import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return process.env.RESPONSE ? process.env.RESPONSE : "Hello NestJS";
  }
}
