import { Test, TestingModule } from '@nestjs/testing';
import { EncadrantController } from './encadrant.controller';

describe('EncadrantController', () => {
  let controller: EncadrantController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [EncadrantController],
    }).compile();

    controller = module.get<EncadrantController>(EncadrantController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
