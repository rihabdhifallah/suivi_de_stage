export class CreateUserDto {
  email!: string;
  password!: string;
  role!: string;

  country?: string;
  phone?: string;
  universite?: string;
}