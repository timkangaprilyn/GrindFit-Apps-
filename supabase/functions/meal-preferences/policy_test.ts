import { validatePreferences } from './policy.ts';
const valid = {budget: 75, plant_only: true, excluded: ['soy'], favorites: ['monggo-bowl']};
Deno.test('allowlists preferences and discards forged owner and unknown personal fields', () => {
  const result = validatePreferences({...valid, firebase_uid: 'other-user', injury: 'private'});
  if ('firebase_uid' in result || 'injury' in result || result.budget !== 75) throw new Error('Unexpected fields');
});
Deno.test('rejects invalid budget, favorites and exclusion values', () => {
  for (const value of [{...valid, budget: 0}, {...valid, budget: 151}, {...valid, plant_only: 'yes'}, {...valid, favorites: ['invented']}, {...valid, excluded: ['unknown']}, {...valid, favorites: null}]) {
    let failed = false;
    try { validatePreferences(value); } catch (_) { failed = true; }
    if (!failed) throw new Error('Invalid preferences accepted');
  }
});
