import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";

import { Invitation } from "./invitation.entity";
import { EncadrantProfessionnel } from "../EncadrantExterne/encadrantprofentity";
import { Offre } from "../offre/offre.entity";

@Injectable()
export class InvitationService {
  constructor(
    @InjectRepository(Invitation)
    private repo: Repository<Invitation>,

    @InjectRepository(EncadrantProfessionnel)
    private encRepo: Repository<EncadrantProfessionnel>,

    @InjectRepository(Offre)
    private offreRepo: Repository<Offre>,
  ) {}

  async invite(encadrantId: number, offreId: number) {
    const encadrant = await this.encRepo.findOneBy({ id: encadrantId });
    const offre = await this.offreRepo.findOneBy({ id: offreId });

    if (!encadrant || !offre) {
      throw new Error("Encadrant ou Offre introuvable");
    }

    const invitation = this.repo.create({
      encadrant,
      offre,
      status: "pending",
    });

    return await this.repo.save(invitation);
  }

  findByOffre(offreId: number) {
    return this.repo.find({
      where: { offre: { id: offreId } },
      relations: ["encadrant"],
    });
  }

  findByEncadrant(encadrantId: number) {
    return this.repo.find({
      where: { encadrant: { id: encadrantId } },
      relations: ["offre"],
    });
  }
}