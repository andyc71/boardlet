// Render marketing artwork around unchanged, native-resolution app captures.
// NODE_PATH must include playwright and sharp. Run from the repository root.
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const sharp = require('sharp');
const root = path.resolve('screenshots/AppStore-2026-10');
const formats = [
 ['iPhone-6.3',1206,2622,'iphone'],
 ['iPhone-6.9',1320,2868,'iphone'],
 ['iPad-13',2064,2752,'ipad'],
 ['iPhone-Duo-outer',1398,2034,'duo-outer'],
 ['iPhone-Duo-inner',2007,2853,'duo-inner'],
];
const copy = [
 ['01-boards','A board for<br>every moment.','Keep favourite pictures organised<br>and ready to use.','#FFDD33'],
 ['02-board','Make it<br>personal.','Bring familiar photos and symbols<br>together on one board.','#68DFA7'],
 ['03-layout','A layout that<br>fits your day.','Choose your page size, grid<br>and orientation.','#FFAACC'],
 ['04-print','From screen<br>to everyday life.','Preview your board, then print<br>or share a PDF.','#FFDD33'],
];
const data = p => 'data:image/png;base64,'+fs.readFileSync(p).toString('base64');
const font = fs.readFileSync('fastlane/screenshots/fonts/Baloo2-Bold.ttf').toString('base64');
const icon = data('PECS Maker/Assets/Assets.xcassets/AppIcon.appiconset/ios-marketing.png');
(async()=>{
 const browser = await chromium.launch({headless:true, executablePath:process.env.CHROME_PATH || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"});
 const manifest=[];
 for(const [name,w,h,source] of formats){
  const dir=path.join(root,'en-US',name);fs.mkdirSync(dir,{recursive:true});
  for(const [slug,title,subtitle,accent] of copy){
   const input=path.join(root,'raw',source,slug+'.png');
   if(!fs.existsSync(input)) continue;
   const meta=await sharp(input).metadata();
   const scale=w/1206, compact=h/w<1.8;
   const header=compact?h*.32:h*.225;
   const maxH=h-header-h*.055, maxW=w*.87;
   const ratio=Math.min(maxW/meta.width,maxH/meta.height);
   const sw=Math.round(meta.width*ratio),sh=Math.round(meta.height*ratio);
   const html=`<!doctype html><html><head><meta charset="utf-8"><style>
   @font-face{font-family:Baloo;src:url(data:font/ttf;base64,${font})}
   *{box-sizing:border-box}body{margin:0;width:${w}px;height:${h}px;overflow:hidden;background:#EDF6FF;color:#003C51;font-family:Arial,sans-serif}
   .wash{position:absolute;inset:0;background:linear-gradient(155deg,#EDF6FF 35%,#CEE6FF 100%)}
   .orb{position:absolute;border-radius:50%;background:#33C5FF;width:${w*.85}px;height:${w*.85}px;left:${-w*.48}px;top:${h*.58}px;opacity:.24}
   .orb2{position:absolute;border-radius:50%;background:${accent};width:${w*.62}px;height:${w*.62}px;right:${-w*.35}px;top:${h*.41}px;opacity:.65}
   header{position:absolute;top:${h*.025}px;left:0;width:100%;text-align:center}
   .brand{display:flex;align-items:center;justify-content:center;gap:${14*scale}px;font:700 ${29*scale}px Baloo;letter-spacing:.3px}
   .brand img{width:${48*scale}px;height:${48*scale}px;border-radius:${12*scale}px}
   h1{font-family:Baloo;font-size:${compact?81*scale:103*scale}px;line-height:1.01;letter-spacing:-${2*scale}px;margin:${compact?12*scale:22*scale}px 0 ${14*scale}px;font-weight:700}
   p{font-size:${compact?29*scale:34*scale}px;line-height:1.35;margin:0;color:#285969}
   .device{position:absolute;top:${header}px;left:${(w-sw)/2}px;width:${sw}px;height:${sh}px;border-radius:${30*scale}px;box-shadow:0 ${24*scale}px ${55*scale}px #003C5130,0 0 0 ${9*scale}px #fff;overflow:hidden;background:white}
   .device img{display:block;width:100%;height:100%}
   .foot{position:absolute;bottom:${h*.018}px;width:100%;text-align:center;font:700 ${19*scale}px Baloo;letter-spacing:${3*scale}px;color:#285969}
   </style></head><body><div class="wash"></div><div class="orb"></div><div class="orb2"></div><header><div class="brand"><img src="${icon}">Boardlet</div><h1>${title}</h1><p>${subtitle}</p></header><div class="device"><img src="${data(input)}"></div><div class="foot">PICTURES. CHOICES. CONNECTION.</div></body></html>`;
   const page=await browser.newPage({viewport:{width:w,height:h},deviceScaleFactor:1});
   await page.setContent(html);await page.evaluate(()=>document.fonts.ready);
   const out=path.join(dir,slug+'.png');
   await page.screenshot({path:out});await page.close();
   // PNG RGB, sRGB, no transparency; preserve exact App Store dimensions.
   const rgb=await sharp(out).flatten({background:'#EDF6FF'}).toColourspace('srgb').png().toBuffer();fs.writeFileSync(out,rgb);
   const check=await sharp(out).metadata();
   if(check.width!==w||check.height!==h||check.hasAlpha)throw Error('Invalid export '+out);
   manifest.push({file:path.relative(root,out),width:w,height:h,source:path.relative(root,input),sourceWidth:meta.width,sourceHeight:meta.height,title:title.replace('<br>',' '),subtitle:subtitle.replace('<br>',' '),hasAlpha:false});
   console.log(path.relative(root,out));
  }
 }
 fs.writeFileSync(path.join(root,'manifest.json'),JSON.stringify(manifest,null,2));
 await browser.close();
})();
