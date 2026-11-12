const fs = require('node:fs');
const path = require('node:path');
for (const directory of ['web', 'C:/Users/Acer/Desktop/grindfit_admin']) {
  const images = path.join(directory, 'images');
  fs.mkdirSync(images, {recursive:true});
  fs.copyFileSync('assets/images/grindfit_logo.png', path.join(images,'grindfit_logo.png'));
  const htmlFile = path.join(directory,'admin.html');
  let html = fs.readFileSync(htmlFile,'utf8');
  html = html.replace('<div class="brand-mark">GF</div>', '<img class="admin-logo admin-logo--login" src="./images/grindfit_logo.png" alt="GrindFit logo" width="160" height="128">');
  html = html.replace('<span class="brand-mark small">GF</span>', '<img class="admin-logo admin-logo--header" src="./images/grindfit_logo.png" alt="" width="72" height="52">');
  html = html.replace('<link rel="icon" href="/favicon.png">', '<link rel="icon" type="image/png" href="./images/grindfit_logo.png">');
  fs.writeFileSync(htmlFile,html);
  const cssFile = path.join(directory,'admin.css');
  const css = fs.readFileSync(cssFile,'utf8');
  fs.writeFileSync(cssFile, css + `\n/* Shared GrindFit branding from the mobile app. */
.admin-logo {
  display: block;
  object-fit: contain;
  flex-shrink: 0;
}
.admin-logo--login {
  width: 160px;
  height: 128px;
  max-width: 100%;
  justify-self: center;
  filter: drop-shadow(0 4px 14px rgba(245, 184, 0, 0.12));
}
.admin-logo--header {
  width: 72px;
  height: 52px;
}
@media (max-width: 480px) {
  .admin-logo--header { width: 56px; height: 44px; }
}
`);
  if (/class="brand-mark(?: small)?">GF/.test(html)) throw Error('Text logo remains');
  if ((html.match(/class="admin-logo /g)||[]).length !== 2) throw Error('Logo placement missing');
  console.log(directory + ': login, header, and favicon logo paths verified');
}
