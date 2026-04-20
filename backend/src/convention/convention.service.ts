import { Injectable } from '@nestjs/common';

@Injectable()
export class ConventionService {

  private conventions: any[] = [];

  // CREATE (company)
  create(body: any) {
    const newConv = {
      id: this.conventions.length + 1,
      ...body,
      status: 'pending',
    };

    this.conventions.push(newConv);
    return newConv;
  }

  // UPDATE STATUS (admin)
  updateStatus(id: number, status: string) {
    const conv = this.conventions.find(c => c.id == id);
    if (conv) {
      conv.status = status;
    }
    return conv;
  }

  // GET ALL (admin)
  findAll() {
    return this.conventions;
  }

  // GET ACCEPTED (student)
  findAccepted() {
    return this.conventions.filter(c => c.status === 'accepted');
  }
  
}