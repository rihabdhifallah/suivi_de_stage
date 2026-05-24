import { Test, TestingModule } from '@nestjs/testing';
import { EncadrementController } from './encadrement.controller';

describe('EncadrementController', () => {
  let controller: EncadrementController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [EncadrementController],
    }).compile();

    controller = module.get<EncadrementController>(EncadrementController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
