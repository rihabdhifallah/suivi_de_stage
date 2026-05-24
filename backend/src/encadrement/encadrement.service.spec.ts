import { Test, TestingModule } from '@nestjs/testing';
import { EncadrementService } from './encadrement.service';

describe('EncadrementService', () => {
  let service: EncadrementService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [EncadrementService],
    }).compile();

    service = module.get<EncadrementService>(EncadrementService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
