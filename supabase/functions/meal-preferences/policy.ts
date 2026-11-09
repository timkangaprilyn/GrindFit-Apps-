export const mealIds = ['egg-rice-banana', 'oats-banana', 'tofu-pechay', 'chicken-tinola',
  'monggo-bowl', 'sardines-cabbage', 'camote-fruit', 'tofu-breakfast', 'chicken-vegetables',
  'tilapia-greens', 'egg-tomato', 'squash-beans', 'banana-peanuts', 'yogurt-fruit', 'corn-fruit', 'peanut-pandesal'];

export function validatePreferences(input: unknown): Record<string, unknown> {
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw new Error('Invalid preferences');
  const v = input as Record<string, unknown>;
  if (typeof v.budget !== 'number' || !Number.isInteger(v.budget) || v.budget < 30 || v.budget > 150 || typeof v.plant_only !== 'boolean') throw new Error('Invalid budget or diet');
  const list = (key: string, allowed: string[]) => {
    const values = v[key];
    if (!Array.isArray(values) || values.length > allowed.length || values.some((s) => typeof s !== 'string' || !allowed.includes(s))) throw new Error(`Invalid ${key}`);
    return [...new Set(values as string[])].sort();
  };
  return {budget: v.budget, plant_only: v.plant_only,
    excluded: list('excluded', ['egg', 'soy', 'fish', 'milk', 'peanut', 'wheat']),
    favorites: list('favorites', mealIds)};
}
