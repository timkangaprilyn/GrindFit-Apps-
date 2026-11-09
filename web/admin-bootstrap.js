const preview = new URLSearchParams(location.search).get('preview') === '1';
try {
  await import(preview ? './admin-preview.js' : './admin.js');
} catch (_) {
  document.getElementById('bootStatus').textContent = 'Could not load the workspace. Check your connection and refresh this page.';
}
