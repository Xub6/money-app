const { createCanvas } = require('canvas');
const fs = require('fs');

const W = 1024, H = 500;
const canvas = createCanvas(W, H);
const ctx = canvas.getContext('2d');

// Background gradient — dark
const bg = ctx.createLinearGradient(0, 0, W, H);
bg.addColorStop(0, '#0D0D0F');
bg.addColorStop(1, '#1A1A1E');
ctx.fillStyle = bg;
ctx.fillRect(0, 0, W, H);

// Subtle gold glow top-left
const glow = ctx.createRadialGradient(180, 160, 0, 180, 160, 320);
glow.addColorStop(0, 'rgba(197,155,99,0.18)');
glow.addColorStop(1, 'rgba(197,155,99,0)');
ctx.fillStyle = glow;
ctx.fillRect(0, 0, W, H);

// Decorative bar chart (right side)
const bars = [
  { x: 620, h: 120, color: '#C59B63' },
  { x: 680, h: 180, color: '#D4AA72' },
  { x: 740, h: 140, color: '#C59B63' },
  { x: 800, h: 220, color: '#E0BC82' },
  { x: 860, h: 160, color: '#C59B63' },
  { x: 920, h: 260, color: '#D4AA72' },
];
const barW = 40;
const baseY = 400;
bars.forEach(b => {
  // Bar shadow
  ctx.fillStyle = 'rgba(0,0,0,0.3)';
  ctx.beginPath();
  ctx.roundRect(b.x + 4, baseY - b.h + 4, barW, b.h, [6, 6, 0, 0]);
  ctx.fill();
  // Bar
  const barGrad = ctx.createLinearGradient(b.x, baseY - b.h, b.x, baseY);
  barGrad.addColorStop(0, b.color);
  barGrad.addColorStop(1, b.color + '88');
  ctx.fillStyle = barGrad;
  ctx.beginPath();
  ctx.roundRect(b.x, baseY - b.h, barW, b.h, [6, 6, 0, 0]);
  ctx.fill();
});

// Base line
ctx.strokeStyle = 'rgba(197,155,99,0.3)';
ctx.lineWidth = 1.5;
ctx.beginPath();
ctx.moveTo(600, baseY);
ctx.lineTo(980, baseY);
ctx.stroke();

// Trend line over bars
ctx.strokeStyle = '#E0BC82';
ctx.lineWidth = 2.5;
ctx.setLineDash([6, 3]);
ctx.beginPath();
ctx.moveTo(640, baseY - 130);
ctx.bezierCurveTo(700, baseY - 170, 780, baseY - 200, 940, baseY - 270);
ctx.stroke();
ctx.setLineDash([]);

// Trend arrow
ctx.fillStyle = '#E0BC82';
ctx.beginPath();
ctx.moveTo(950, baseY - 278);
ctx.lineTo(938, baseY - 264);
ctx.lineTo(944, baseY - 268);
ctx.lineTo(942, baseY - 280);
ctx.closePath();
ctx.fill();

// Divider line left side
ctx.strokeStyle = 'rgba(197,155,99,0.15)';
ctx.lineWidth = 1;
ctx.beginPath();
ctx.moveTo(580, 60);
ctx.lineTo(580, 440);
ctx.stroke();

// Gold coin icon (circle)
ctx.beginPath();
ctx.arc(90, 110, 42, 0, Math.PI * 2);
const coinGrad = ctx.createRadialGradient(80, 98, 4, 90, 110, 42);
coinGrad.addColorStop(0, '#F0D080');
coinGrad.addColorStop(0.5, '#C59B63');
coinGrad.addColorStop(1, '#8B6A3A');
ctx.fillStyle = coinGrad;
ctx.fill();

// $ sign on coin
ctx.fillStyle = '#5C3D10';
ctx.font = 'bold 42px sans-serif';
ctx.textAlign = 'center';
ctx.textBaseline = 'middle';
ctx.fillText('$', 90, 112);

// App name
ctx.textAlign = 'left';
ctx.textBaseline = 'alphabetic';
ctx.font = 'bold 64px sans-serif';
const nameGrad = ctx.createLinearGradient(60, 0, 460, 0);
nameGrad.addColorStop(0, '#F0D080');
nameGrad.addColorStop(1, '#C59B63');
ctx.fillStyle = nameGrad;
ctx.fillText('錢錢管家', 60, 230);

// Tagline
ctx.font = '22px sans-serif';
ctx.fillStyle = 'rgba(255,255,255,0.65)';
ctx.fillText('記帳・預算・投資  一站掌握', 62, 275);

// Feature pills
const pills = ['📒 智慧記帳', '📈 即時股價', '🏦 多幣賬戶', '🔒 AES 加密'];
let px = 60;
const py = 360;
pills.forEach(text => {
  const tw = ctx.measureText(text).width;
  const pw = tw + 28;
  // Pill bg
  ctx.fillStyle = 'rgba(197,155,99,0.15)';
  ctx.strokeStyle = 'rgba(197,155,99,0.4)';
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.roundRect(px, py, pw, 36, 18);
  ctx.fill();
  ctx.stroke();
  // Pill text
  ctx.fillStyle = '#D4AA72';
  ctx.font = '16px sans-serif';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, px + 14, py + 18);
  px += pw + 12;
});

// Bottom brand
ctx.font = '15px sans-serif';
ctx.fillStyle = 'rgba(255,255,255,0.3)';
ctx.textBaseline = 'alphabetic';
ctx.textAlign = 'left';
ctx.fillText('by Qoryva', 62, 455);

// Save
const outPath = 'docs/feature-graphic.png';
fs.writeFileSync(outPath, canvas.toBuffer('image/png'));
console.log('saved:', outPath);
