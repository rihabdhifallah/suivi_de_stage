import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Offre } from "./offre.entity";

@Injectable()
export class OffreService {
 

  constructor(
    @InjectRepository(Offre)
    private repo: Repository<Offre>,
  ) {}

  // CREATE
  create(data: any) {
    data.places = Number(data.places);
    return this.repo.save(data);
  }

  // GET BY COMPANY
  findByCompany(email: string) {
    return this.repo.find({
      where: { companyEmail: email },
      order: { id: "DESC" },
    });
  }

  // DELETE (optionnel)
  delete(id: number) {
    return this.repo.delete(id);
  }
  update(id: number, data: any) {
  return this.repo.update(id, data);
}
updateStatus(id: number, active: boolean) {
  return this.repo.update(id, { active });
}

}