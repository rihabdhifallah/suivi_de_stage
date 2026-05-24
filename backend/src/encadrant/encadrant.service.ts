import { Injectable } from '@nestjs/common';

@Injectable()
export class EncadrantService {

  getStats() {
    return {
      etudiants: 10,
      rapports: 5,
      encadrements: 3,
    };
  }
}