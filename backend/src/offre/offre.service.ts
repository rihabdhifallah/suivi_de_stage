import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Offre } from "./offre.entity";
import { User } from "../users/user.entity";

@Injectable()
export class OffreService {

 constructor(
  @InjectRepository(Offre)
  private repo: Repository<Offre>,
) {}

  create(data: any) {
  console.log("DATA RECEIVED:", data);
  console.log(typeof data.active, data.active);

  return this.repo.save({
    titre: data.titre,
    domaine: data.domaine,
    duree: data.duree,
    niveau: data.niveau,
    places: Number(data.places),
    companyEmail: data.companyEmail,
    companyName: data.companyName ?? null,
    city: data.city ?? null,
    dateDebut: data.dateDebut ?? null,
    dateFin: data.dateFin ?? null,
    skills: data.skills ?? [],
    active: true,
    typeStage: data.typeStage ?? 'Présentiel',
    remuneration: data.remuneration ?? null,
  });
}

 

  findByCompany(email: string) {
    return this.repo.find({
      where: { companyEmail: email },
      order: { id: "DESC" },
      relations: ["invitations", "invitations.encadrant"],
    });
  }

  // DELETE
  delete(id: number) {
    return this.repo.delete(id);
  }

  update(id: number, data: any) {
    return this.repo.update(id, data);
  }

  updateStatus(id: number, active: boolean) {
    return this.repo.update(id, { active });
  }

  async findAll() {
    const offres = await this.repo.find({
      where: { active: true },
      order: { id: "DESC" },
      relations: ["invitations", "invitations.encadrant"],
    });

    const emails = offres.map(o => o.companyEmail).filter(e => !!e);
    if (emails.length > 0) {
      const users = await this.repo.manager.createQueryBuilder(User, "user")
        .where("user.email IN (:...emails)", { emails })
        .getMany();

      const companyMap = new Map(users.map(u => [u.email.toLowerCase(), u]));
      return offres.map(o => {
        const company = companyMap.get(o.companyEmail.toLowerCase());
        return {
          ...o,
          companyPhoto: company?.photo || null,
        };
      });
    }

    return offres;
  }

findAllForAdmin() {
  return this.repo.find({
    order: { id: "DESC" },
  });
}

ffindForStudents() {
  return this.repo.find({
    order: { id: "DESC" },
  });
}

findOne(id: number) {
  return this.repo.findOne({
    where: { id },
    relations: ["invitations", "invitations.encadrant"],
  });
}

// Invitations pour un encadrant professionnel (par son email de login)
// Retourne les OFFRES de l'entreprise de l'encadrant,
// avec les étudiants acceptés si disponibles
async findInvitationsForEncadrant(encadrantEmail: string) {
  const email = encadrantEmail.toLowerCase().trim();

  // 1. Find EncadrantProfessionnel + companyId by email
  const encadrantRows = await this.repo.manager.query(`
    SELECT id, "companyId" FROM encadrant_professionnel WHERE LOWER(email) = $1 LIMIT 1
  `, [email]);

  if (!encadrantRows || encadrantRows.length === 0) return [];

  const encadrant = encadrantRows[0];
  const encadrantId = encadrant.id;
  const companyId   = encadrant.companyId;

  // 2a. Find offres via invitation table (if any)
  const invitedOffreRows = await this.repo.manager.query(`
    SELECT
      i.id            AS "invitationId",
      i.status        AS "invitationStatus",
      i."createdAt"   AS "invitationDate",
      o.id            AS "offreId",
      o.titre,
      o.domaine,
      o.duree,
      o.niveau,
      o.places,
      o.city,
      o."companyEmail",
      o."companyName",
      o."dateDebut",
      o."dateFin",
      o.skills
    FROM invitation i
    INNER JOIN offre o ON o.id = i."offreId"
    WHERE i."encadrantId" = $1
    ORDER BY i."createdAt" DESC
  `, [encadrantId]);

  // 2b. Find offres via companyId (company's offres)
  let companyOffreRows: any[] = [];
  if (companyId) {
    // Find company email from user table
    const companyUser = await this.repo.manager.query(`
      SELECT email FROM "user" WHERE id = $1 LIMIT 1
    `, [companyId]);

    if (companyUser && companyUser.length > 0) {
      const companyEmail = companyUser[0].email;
      companyOffreRows = await this.repo.manager.query(`
        SELECT
          o.id            AS "offreId",
          o.titre,
          o.domaine,
          o.duree,
          o.niveau,
          o.places,
          o.city,
          o."companyEmail",
          o."companyName",
          o."dateDebut",
          o."dateFin",
          o.skills,
          o."createdAt"   AS "offreDate"
        FROM offre o
        WHERE LOWER(o."companyEmail") = LOWER($1)
        ORDER BY o."createdAt" DESC
      `, [companyEmail]);
    }
  }

  // 3. Merge: invited offres + company offres (deduplicate by offreId)
  const seenOffreIds = new Set<number>();
  const allOffreRows: any[] = [];

  for (const row of invitedOffreRows) {
    if (!seenOffreIds.has(row.offreId)) {
      seenOffreIds.add(row.offreId);
      allOffreRows.push({ ...row, source: 'invitation' });
    }
  }
  for (const row of companyOffreRows) {
    if (!seenOffreIds.has(row.offreId)) {
      seenOffreIds.add(row.offreId);
      allOffreRows.push({
        ...row,
        invitationId: null,
        invitationStatus: 'pending',
        invitationDate: row.offreDate,
        source: 'company',
      });
    }
  }

  if (allOffreRows.length === 0) return [];

  const offreIds = allOffreRows.map((r: any) => r.offreId);

  // 4. Find accepted applications for those offres
  const appRows = await this.repo.manager.query(`
    SELECT
      a.id            AS "appId",
      a."offreId",
      a.status        AS "appStatus",
      a."studentId",
      a."studentName",
      a."studentEmail",
      a.phone         AS "studentPhone",
      a.etablissement AS "studentEtab",
      a.niveau        AS "studentNiveau",
      a."createdAt"   AS "appCreatedAt",
      u.photo         AS "studentPhoto",
      u.specialite    AS "studentSpecialite",
      u.universite    AS "studentUniversite"
    FROM application a
    LEFT JOIN "user" u ON u.id = a."studentId"
    WHERE a."offreId" = ANY($1::int[])
      AND a.status IN ('accepted', 'signed_by_company', 'fully_signed')
    ORDER BY a."createdAt" DESC
  `, [offreIds]);

  // Group accepted students by offreId
  const appsByOffre = new Map<number, any[]>();
  for (const app of appRows) {
    const list = appsByOffre.get(app.offreId) ?? [];
    list.push({
      studentName:   app.studentName,
      studentEmail:  app.studentEmail,
      phone:         app.studentPhone,
      telephone:     app.studentPhone,
      etablissement: app.studentEtab,
      university:    app.studentUniversite,
      niveau:        app.studentNiveau,
      specialite:    app.studentSpecialite,
      photo:         app.studentPhoto,
      studentPhoto:  app.studentPhoto,
      status:        app.appStatus,
    });
    appsByOffre.set(app.offreId, list);
  }

  // 5. Build result: one entry per offre
  return allOffreRows.map((row: any) => {
    const students = appsByOffre.get(row.offreId) ?? [];
    const firstStudent = students[0] ?? null;
    return {
      id:        row.invitationId ?? row.offreId,
      status:    firstStudent ? firstStudent.status : row.invitationStatus,
      createdAt: row.invitationDate,
      offre: {
        id:           row.offreId,
        titre:        row.titre,
        domaine:      row.domaine,
        duree:        row.duree,
        niveau:       row.niveau,
        places:       row.places,
        city:         row.city,
        companyEmail: row.companyEmail,
        companyName:  row.companyName,
        dateDebut:    row.dateDebut,
        dateFin:      row.dateFin,
        skills:       row.skills,
      },
      application: firstStudent,
      students:    students,
    };
  });
}
}
