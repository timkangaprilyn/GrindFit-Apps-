export async function requestAdminData({config, token, body, fetcher = fetch}) {
  if (!token) throw new Error('Sign in with an admin account first.');
  const response = await fetcher(`${config.url}/functions/v1/admin-member-data`, {
    method: 'POST', headers: {apikey: config.publishableKey, Authorization: `Bearer ${token}`, 'Content-Type': 'application/json'},
    body: JSON.stringify(body), signal: AbortSignal.timeout(15000),
  });
  if (!response.ok) {
    if (response.status === 404) throw new Error('Supabase admin function is not deployed. Run deploy-live.ps1 -AdminDashboard.');
    if (response.status === 403) throw new Error('Supabase member data requires a verified Firebase admin role.');
    if (response.status === 401) throw new Error('Your staff session could not be verified. Sign in again.');
    throw new Error('Could not load Supabase data. Check connection and retry.');
  }
  return response.json();
}

// Trainer account management through the Supabase `admin-staff` function.
export async function requestStaff({config, token, body, fetcher = fetch}) {
  if (!token) throw new Error('Sign in with an admin account first.');
  let response;
  try {
    response = await fetcher(`${config.url}/functions/v1/admin-staff`, {
      method: 'POST', headers: {apikey: config.publishableKey, Authorization: `Bearer ${token}`, 'Content-Type': 'application/json'},
      body: JSON.stringify(body), signal: AbortSignal.timeout(20000),
    });
  } catch (_) {
    throw new Error('Could not reach Supabase. Check your connection and retry.');
  }
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    if (response.status === 404 && !data.error) throw new Error('Trainer management is not deployed yet. Run deploy-live.ps1 -StaffAccounts (see supabase/README.md).');
    if (response.status === 403) throw new Error('Only admin accounts can manage trainers.');
    if (response.status === 401) throw new Error('Your staff session could not be verified. Sign in again.');
    throw new Error(data.error || 'Could not complete the request. Try again.');
  }
  return data;
}

// Reads the signed-in user's own account record (password timestamps).
export async function lookupOwnAccount({apiKey, idToken, fetcher = fetch}) {
  const response = await fetcher(`https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${encodeURIComponent(apiKey)}`, {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({idToken}), signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new Error('Could not check your account security settings.');
  const data = await response.json();
  return data.users?.[0] ?? null;
}
