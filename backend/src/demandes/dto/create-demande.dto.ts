export class CreateDemandeDto {
  student_id?: number;
  student_name?: string;
  student_email?: string;

  specialite?: string;
  duree?: string;
  date_prevue?: string;

  entreprise?: string;
  secteur?: string;
  adresse?: string;
  tel_entreprise?: string;
  email_entreprise?: string;

  encadrant_nom?: string;
  poste_encadrant?: string;
  tel_encadrant?: string;
  email_encadrant?: string;

  titre?: string;
  mission?: string;
  skills?: string;

  start_date?: string;
  end_date?: string;

  remuneration?: string;
  note?: string;
  found_via?: string;

  status?: string;
}