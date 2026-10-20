const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const root = path.join(__dirname, 'exports');
async function walk(dir) {
  const result = [];
  for (const f of fs.readdirSync(dir, {withFileTypes:true})) {
    const p = path.join(dir,f.name);
    if(f.isDirectory()) result.push(...await walk(p));
    else if(p.endsWith('.png')) result.push(p);
  }
  return result.sort();
}
(async()=>{
  const files=await walk(path.join(root,'ios'));
  const manifest=[];
  for(const f of files){
    const [w,h]=path.basename(path.dirname(path.dirname(f))).split('x').map(Number);
    const m=await sharp(f).metadata();
    if(m.width!==w||m.height!==h||m.hasAlpha||m.channels!==3) throw Error('Invalid export: '+f);
    manifest.push({file:path.relative(root,f),width:w,height:h,channels:m.channels,hasAlpha:m.hasAlpha});
  }
  fs.writeFileSync(path.join(root,'verification.json'),JSON.stringify(manifest,null,2)+'\n');
  for(const [device,size] of [['iphone','1320x2868'],['ipad','2064x2752'],['duo-outer','1398x2034']]){
    const set=files.filter(f=>f.includes('/'+device+'/'+size+'/'));
    if(!set.length)continue;
    let x=0;const images=[];
    for(const f of set){const {data,info}=await sharp(f).resize({height:600}).toBuffer({resolveWithObject:true});images.push({input:data,left:x,top:0});x+=info.width;}
    await sharp({create:{width:x,height:600,channels:3,background:'#EDF6FF'}}).composite(images).png().toFile(path.join(root,device+'-preview.png'));
  }
  console.log(`PASS: ${files.length} PNGs; exact dimensions, RGB, no alpha.`);
})().catch(e=>{console.error(e);process.exit(1)});
