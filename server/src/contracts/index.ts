import { PlayerContracts } from './player-contracts.js';
import { ScoreContracts } from './score-contracts.js';

// Export all contracts for SDK generation
export const AllContracts = {
  Players: PlayerContracts,
  Scores: ScoreContracts,
};

// Export individual contract groups
export { PlayerContracts, ScoreContracts };
export * from './player-contracts.js';
export * from './score-contracts.js';