// Password rule for HIMS users - the same as Identity & Org's PasswordPolicy (WSO2 applies its own tenant policy as well).
// Shared by every zone (copied in by sync-shared.sh).

/** Null when the password is acceptable, otherwise what is wrong with it. */
export function passwordProblem(p: string): string | null {
  if (p.length < 8 || p.length > 64) return 'Password must be 8-64 characters long.';
  if (!/[A-Z]/.test(p) || !/[a-z]/.test(p) || !/[0-9]/.test(p) || !/[^A-Za-z0-9]/.test(p)) return 'Password must contain an uppercase letter, a lowercase letter, a digit and a special character.';
  if (/\s/.test(p)) return 'Password must not contain spaces.';
  return null;
}

export const PASSWORD_RULE = '8-64 characters with an uppercase letter, a lowercase letter, a digit and a special character, no spaces.';
