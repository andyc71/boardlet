const { chromium } = require('playwright');
const { pathToFileURL } = require('url');
const path = require('path');

async function main() {
  const browser = await chromium.launch({
    headless: true,
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
  });
  try {
    for (const variant of ['centered', 'split', 'focus']) {
      const page = await browser.newPage({ viewport: { width: 2732, height: 2048 }, deviceScaleFactor: 1 });
      const url = pathToFileURL(path.join(__dirname, 'render.html')).href + `?variant=${variant}`;
      await page.goto(url);
      await page.evaluate(() => document.fonts.ready);
      await page.locator('.screen img').evaluate(img => img.decode());
      await page.screenshot({ path: path.join(__dirname, `${variant}.png`) });
      await page.close();
    }
  } finally {
    await browser.close();
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
