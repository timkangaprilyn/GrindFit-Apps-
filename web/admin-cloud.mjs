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
