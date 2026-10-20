const fs=require('fs'),path=require('path'),sharp=require('sharp');
const root=path.resolve('screenshots/AppStore-2026-10');
(async()=>{
 const items=JSON.parse(fs.readFileSync(path.join(root,'manifest.json')));
 const groups=[...new Set(items.map(i=>i.file.split('/')[1]))];
 const columns=4,cellW=330,cellH=780,pad=26;
 const composites=[];
 for(let r=0;r<groups.length;r++){
  const entries=items.filter(i=>i.file.split('/')[1]===groups[r]);
  const label=Buffer.from(`<svg width="1320" height="54"><text x="8" y="36" font-family="Arial" font-size="25" fill="#003C51">${groups[r]} · ${entries[0].width} × ${entries[0].height}</text></svg>`);
  composites.push({input:label,left:pad,top:pad+r*cellH});
  for(let c=0;c<entries.length;c++){
   const thumb=await sharp(path.join(root,entries[c].file)).resize(cellW-22,cellH-80,{fit:'inside'}).png().toBuffer();
   composites.push({input:thumb,left:pad+c*cellW,top:pad+r*cellH+60});
  }
 }
 await sharp({create:{width:columns*cellW+pad*2,height:groups.length*cellH+pad*2,channels:3,background:'#FFFFFF'}}).composite(composites).png().toFile(path.join(root,'preview.png'));
 const html=`<!doctype html><meta charset="utf-8"><title>Boardlet · App Store screenshots</title><style>body{background:#edf6ff;color:#003c51;font:17px system-ui;margin:40px}h1{font-size:36px}.grid{display:grid;grid-template-columns:repeat(4,minmax(140px,1fr));gap:22px;margin-bottom:50px}img{width:100%;border-radius:12px;box-shadow:0 10px 30px #003c5120}a{color:inherit;text-decoration:none}small{display:block;padding-top:8px}aside{background:#ffeb85;padding:18px;border-radius:14px;max-width:900px}</style><h1>Boardlet</h1><p>App Store screenshot artwork · English · 18 October 2026</p><aside>Completed: iPhone, 13-inch iPad and iPhone Duo outer display.<br>Duo inner-display captures are pending: unlock the Mac to access the simulator’s fold controls.</aside>${groups.map(g=>{const e=items.filter(i=>i.file.split('/')[1]===g);return `<h2>${g} <small>${e[0].width} × ${e[0].height} · opaque RGB PNG</small></h2><div class="grid">${e.map(i=>`<a href="${i.file}"><img src="${i.file}"><small>${i.title}</small></a>`).join('')}</div>`}).join('')}<p><a href="https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/">Apple screenshot specifications</a></p>`;
 fs.writeFileSync(path.join(root,'index.html'),html);
 console.log(`${items.length} exports; gallery and contact sheet created.`);
})();
