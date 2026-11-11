// Pure helpers for trainer assignment and coaching requests (no Firebase imports).

// Count updates needed when a member moves from one trainer to another.
// Only trainers with a public profile document carry a memberCount.
export function countMoves(previousUid, nextUid, profileIds) {
  if (previousUid === nextUid) return [];
  const moves = [];
  if (previousUid && profileIds.has(previousUid)) moves.push({uid: previousUid, delta: -1});
  if (nextUid && profileIds.has(nextUid)) moves.push({uid: nextUid, delta: 1});
  return moves;
}

// Assigned-member totals per trainer profile, from the loaded member list.
export function trainerCounts(members, profileIds) {
  const counts = new Map([...profileIds].map((uid) => [uid, 0]));
  for (const member of members) {
    if (member.trainerUid && counts.has(member.trainerUid)) counts.set(member.trainerUid, counts.get(member.trainerUid) + 1);
  }
  return counts;
}

// Profile fields an admin may save, trimmed and bounded like firestore.rules.
export function cleanTrainerProfile({displayName = '', specialty = '', bio = '', active = true} = {}) {
  const name = String(displayName).trim().replace(/\s+/g, ' ');
  if (name.length < 2 || name.length > 80) throw new Error('Enter the trainer name (2–80 characters).');
  const cleanSpecialty = String(specialty).trim().replace(/\s+/g, ' ');
  if (cleanSpecialty.length > 60) throw new Error('Keep the specialty under 60 characters.');
  const cleanBio = String(bio).trim();
  if (cleanBio.length > 400) throw new Error('Keep the bio under 400 characters.');
  return {displayName: name, specialty: cleanSpecialty, bio: cleanBio, active: active === true};
}

export function sortRequests(requests) {
  const time = (value) => value?.toMillis?.() ?? (value instanceof Date ? value.getTime() : 0);
  return [...requests].sort((a, b) => time(a.createdAt) - time(b.createdAt));
}
