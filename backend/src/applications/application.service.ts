import { Injectable, BadRequestException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository, Not } from "typeorm";
import { Application } from "./application.entity";
import { Offre } from "../offre/offre.entity";
import { User } from "../users/user.entity";
import { Notification } from "../notifications/notification.entity";
import { EncadrantProfessionnel } from "../EncadrantExterne/encadrantprofentity";

@Injectable()
export class ApplicationService {

  constructor(
    @InjectRepository(Application)
    private repo: Repository<Application>,

    @InjectRepository(Notification)
    private notifRepo: Repository<Notification>,

    @InjectRepository(User)
    private userRepo: Repository<User>,

    @InjectRepository(EncadrantProfessionnel)
    private encRepo: Repository<EncadrantProfessionnel>,
  ) {}

  async findByCompany(email: string) {
    const apps = await this.repo
      .createQueryBuilder("app")
      .leftJoinAndSelect("app.offre", "offre")
      .where("LOWER(app.companyEmail) = LOWER(:email)", { email })
      .getMany();

    const studentIds = apps.map(app => app.studentId).filter(id => !!id);
    if (studentIds.length > 0) {
      const users = await this.repo.manager.createQueryBuilder(User, "user")
        .where("user.id IN (:...studentIds)", { studentIds })
        .getMany();

      const userMap = new Map(users.map(u => [u.id, u]));
      return apps.map(app => {
        const user = userMap.get(app.studentId);
        return {
          ...app,
          studentPhoto: user?.photo || null,
        };
      });
    }

    return apps;
  }

  // Get accepted applications for an encadrant professionnel (by their email)
  async findByEncadrant(encadrantEmail: string) {
    const email = encadrantEmail.toLowerCase().trim();

    // 1. Find all offres where this encadrant is invited
    const invitations = await this.repo.manager.query(`
      SELECT i."offreId"
      FROM invitation i
      INNER JOIN encadrant_professionnel ep ON ep.id = i."encadrantId"
      WHERE LOWER(ep.email) = $1
    `, [email]);

    if (!invitations || invitations.length === 0) return [];

    const offreIds = invitations.map((inv: any) => inv.offreId);

    // 2. Find accepted applications for those offres
    const apps = await this.repo
      .createQueryBuilder("app")
      .leftJoinAndSelect("app.offre", "offre")
      .where("app.offreId IN (:...offreIds)", { offreIds })
      .andWhere("app.status IN (:...statuses)", {
        statuses: ["accepted", "signed_by_company", "fully_signed"],
      })
      .getMany();

    if (apps.length === 0) return [];

    // 3. Enrich with student user data
    const studentIds = apps.map(a => a.studentId).filter(id => !!id);
    const users = studentIds.length > 0
      ? await this.repo.manager.createQueryBuilder(User, "user")
          .where("user.id IN (:...studentIds)", { studentIds })
          .getMany()
      : [];

    const userMap = new Map(users.map(u => [u.id, u]));

    return apps.map(app => {
      const user = userMap.get(app.studentId);
      return {
        ...app,
        studentPhoto:      user?.photo      || null,
        studentNiveau:     user?.niveau     || null,
        studentSpecialite: user?.specialite || null,
        studentUniversite: user?.universite || null,
        studentPhone:      user?.phone      || app.phone || null,
        studentAdresse:    user?.adresse    || null,
        studentVille:      user?.adresse    || app.city  || null,
        studentPrenom:     user?.prenom     || null,
      };
    });
  }

  findByStudent(studentId: number) {
    return this.repo.find({
      where: { studentId },
      relations: ["offre", "offre.invitations", "offre.invitations.encadrant", "stage"],
      order: { id: "DESC" },
    });
  }

  async apply(data: any) {
    const offer = await this.repo.manager.findOne(Offre, { where: { id: data.stageId } });
    if (!offer) {
      throw new BadRequestException("L'offre demandée n'existe pas");
    }

    if (offer.places <= 0) {
      throw new BadRequestException("Le nombre maximal de places pour cette offre a été atteint.");
    }

    return this.repo.save({
      studentId: data.studentId,
      offre: { id: data.stageId },
      companyEmail: data.companyEmail,
      studentEmail: data.studentEmail,
      studentName: data.studentName,
      motivation: data.motivation,
      phone: data.phone,
      niveau: data.niveau,
      city: data.city,
      date: data.date,
      etablissement: data.etablissement,
      duree: data.duree,
      note: data.note,
      cv: data.cv,
      typeStage: data.typeStage,
      status: "pending",
    });
  }

  async checkPlaces(stageId: number) {
    const offer = await this.repo.manager.findOne(Offre, { where: { id: stageId } });
    if (!offer) {
      throw new BadRequestException("L'offre demandée n'existe pas");
    }

    return {
      isFull: offer.places <= 0,
      places: offer.places,
    };
  }

  async signCompany(id: number, body: any) {
    return this.repo.update(id, {
      signatureCompany: body.signature,
      status: "signed_by_company",
    });
  }

  async signStudent(id: number, body: any) {
    return this.repo.update(id, {
      signatureStudent: body.signature,
      status: "fully_signed",
    });
  }

  async accept(id: number) {
    const app = await this.repo.findOne({
      where: { id },
      relations: ["offre"]
    });

    if (!app) {
      throw new BadRequestException("Candidature introuvable");
    }

    if (app.status !== "accepted") {
      if (app.offre) {
        const offer = app.offre;
        if (offer.places <= 0) {
          throw new BadRequestException("Il n'y a plus de places disponibles pour cette offre.");
        }
        offer.places = offer.places - 1;
        await this.repo.manager.save(offer);
      }
    }

    await this.repo.update(id, { status: "accepted" });

    // ── Notifier l'encadrant professionnel lié à cette offre ──────────────
    if (app.offre) {
      try {
        // Trouver l'encadrant pro invité sur cette offre
        const invitations = await this.repo.manager.query(`
          SELECT ep.id, ep.email, ep."nomComplet"
          FROM invitation i
          INNER JOIN encadrant_professionnel ep ON ep.id = i."encadrantId"
          WHERE i."offreId" = $1
          LIMIT 1
        `, [app.offre.id]);

        if (invitations && invitations.length > 0) {
          const encadrant = invitations[0];
          // Trouver le User correspondant à l'encadrant pro
          const encUser = await this.userRepo.findOne({
            where: { email: encadrant.email.toLowerCase() }
          });

          if (encUser) {
            const studentName = app.studentName || app.studentEmail || 'Un étudiant';
            const offreTitre  = app.offre.titre || 'une offre';

            await this.notifRepo.save({
              user:    encUser,
              type:    'accept',
              title:   `Nouvel étudiant accepté`,
              message: `${studentName} a été accepté(e) sur l'offre "${offreTitre}". Vous pouvez le/la retrouver dans vos invitations.`,
              entityId: app.offre.id,
              read:    false,
            });
          }
        }
      } catch (e) {
        // Non-bloquant : on log mais on ne fait pas échouer l'acceptation
        console.error('Notification encadrant pro failed (non-blocking):', e);
      }
    }

    return { success: true };
  }

  async refuse(id: number) {
    const app = await this.repo.findOne({
      where: { id },
      relations: ["offre"]
    });

    if (!app) {
      throw new BadRequestException("Candidature introuvable");
    }

    if (app.status === "accepted") {
      if (app.offre) {
        const offer = app.offre;
        offer.places = offer.places + 1;
        await this.repo.manager.save(offer);
      }
    }

    return this.repo.update(id, {
      status: "refused",
    });
  }
}