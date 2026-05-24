import { Test, TestingModule } from '@nestjs/testing';
import { EncadrantService } from './encadrant.service';

describe('EncadrantService', () => {
  let service: EncadrantService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [EncadrantService],
    }).compile();

    service = module.get<EncadrantService>(EncadrantService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
