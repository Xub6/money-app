const { createCanvas } = require('canvas');
const fs = require('fs');

const SIZE = 1024;
const canvas = createCanvas(SIZE, SIZE);
const ctx = canvas.getContext('2d');

function roundRect(x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}

function el(cx, cy, rx, ry, angle = 0) {
  ctx.beginPath();
  ctx.ellipse(cx, cy, rx, ry, angle, 0, Math.PI * 2);
  ctx.closePath();
}

// ── Background: rich gold gradient ──────────────────────
const bgGrad = ctx.createRadialGradient(420, 350, 60, 512, 512, 720);
bgGrad.addColorStop(0, '#FFEBA0');
bgGrad.addColorStop(0.45, '#D9AC42');
bgGrad.addColorStop(1, '#7A5208');
roundRect(0, 0, SIZE, SIZE, 170);
ctx.fillStyle = bgGrad;
ctx.fill();

// border shine
ctx.save();
roundRect(18, 18, SIZE - 36, SIZE - 36, 155);
ctx.strokeStyle = 'rgba(255,245,190,0.4)';
ctx.lineWidth = 16;
ctx.stroke();
ctx.restore();

// ── Ground shadow ────────────────────────────────────────
ctx.save();
el(512, 980, 270, 38);
const sg = ctx.createRadialGradient(512, 980, 8, 512, 980, 270);
sg.addColorStop(0, 'rgba(0,0,0,0.4)');
sg.addColorStop(1, 'rgba(0,0,0,0)');
ctx.fillStyle = sg;
ctx.fill();
ctx.restore();

// ────────────────────────────────────────────────────────
// CHARACTER (centered, head dominant)
// Head center ~Y=590, radius ~230 → big round head
// Hat on top of head
// Body below ~Y=820

const CX = 512;
const HEAD_CY = 600;
const HEAD_RX = 225;
const HEAD_RY = 240;

// ── Circle backdrop behind character ────────────────────
ctx.save();
// solid warm-cream disc
ctx.beginPath();
ctx.arc(CX, HEAD_CY + 100, 390, 0, Math.PI * 2);
ctx.fillStyle = 'rgba(255,245,200,0.28)';
ctx.fill();
// inner bright glow
const circleGrad = ctx.createRadialGradient(CX - 40, HEAD_CY - 30, 40, CX, HEAD_CY + 60, 340);
circleGrad.addColorStop(0, 'rgba(255,252,230,0.55)');
circleGrad.addColorStop(0.5, 'rgba(255,240,180,0.25)');
circleGrad.addColorStop(1, 'rgba(220,180,60,0.0)');
ctx.beginPath();
ctx.arc(CX, HEAD_CY + 60, 340, 0, Math.PI * 2);
ctx.fillStyle = circleGrad;
ctx.fill();
ctx.restore();

// ── Neck ────────────────────────────────────────────────
ctx.save();
el(CX, 840, 85, 65);
ctx.fillStyle = '#F4BF88';
ctx.fill();
ctx.restore();

// ── Body / Suit ──────────────────────────────────────────
ctx.save();
// main coat shape
ctx.beginPath();
ctx.ellipse(CX, 940, 310, 140, 0, Math.PI, 0);
ctx.fillStyle = '#1B2C4E';
ctx.fill();
ctx.fillRect(CX - 310, 940, 620, 90);
ctx.restore();

// coat side depth
ctx.save();
el(CX - 260, 960, 60, 90);
ctx.fillStyle = '#142240';
ctx.fill();
el(CX + 260, 960, 60, 90);
ctx.fillStyle = '#142240';
ctx.fill();
ctx.restore();

// lapels
ctx.save();
// left
ctx.beginPath();
ctx.moveTo(CX, 860);
ctx.lineTo(CX - 135, 920);
ctx.lineTo(CX - 155, 1020);
ctx.lineTo(CX - 42, 950);
ctx.closePath();
ctx.fillStyle = '#253E6A';
ctx.fill();
// right
ctx.beginPath();
ctx.moveTo(CX, 860);
ctx.lineTo(CX + 135, 920);
ctx.lineTo(CX + 155, 1020);
ctx.lineTo(CX + 42, 950);
ctx.closePath();
ctx.fillStyle = '#253E6A';
ctx.fill();
ctx.restore();

// shirt front
ctx.save();
ctx.beginPath();
ctx.moveTo(CX - 42, 870);
ctx.lineTo(CX, 888);
ctx.lineTo(CX + 42, 870);
ctx.lineTo(CX + 42, 950);
ctx.lineTo(CX, 968);
ctx.lineTo(CX - 42, 950);
ctx.closePath();
ctx.fillStyle = '#FEFDF4';
ctx.fill();
ctx.restore();

// bowtie
ctx.save();
// left wing
ctx.beginPath();
ctx.moveTo(CX, 882);
ctx.lineTo(CX - 44, 868);
ctx.lineTo(CX - 42, 900);
ctx.closePath();
ctx.fillStyle = '#C8A020';
ctx.fill();
// right wing
ctx.beginPath();
ctx.moveTo(CX, 882);
ctx.lineTo(CX + 44, 868);
ctx.lineTo(CX + 42, 900);
ctx.closePath();
ctx.fillStyle = '#C8A020';
ctx.fill();
// knot
el(CX, 886, 11, 14);
ctx.fillStyle = '#9A7808';
ctx.fill();
ctx.restore();

// ── Head (big, round, Monopoly chibi) ───────────────────
// drop shadow
ctx.save();
el(CX + 8, HEAD_CY + 12, HEAD_RX, HEAD_RY);
ctx.fillStyle = 'rgba(0,0,0,0.18)';
ctx.fill();
ctx.restore();

// head base
ctx.save();
el(CX, HEAD_CY, HEAD_RX, HEAD_RY);
const hg = ctx.createRadialGradient(CX - 60, HEAD_CY - 70, 20, CX, HEAD_CY, 240);
hg.addColorStop(0, '#FDDDB0');
hg.addColorStop(0.55, '#F8C278');
hg.addColorStop(1, '#E8A050');
ctx.fillStyle = hg;
ctx.fill();
ctx.restore();

// ── Ears ────────────────────────────────────────────────
ctx.save();
el(CX - HEAD_RX + 12, HEAD_CY + 20, 48, 60);
ctx.fillStyle = '#F2B870';
ctx.fill();
el(CX - HEAD_RX + 12, HEAD_CY + 20, 30, 40);
ctx.fillStyle = '#E09060';
ctx.fill();
el(CX + HEAD_RX - 12, HEAD_CY + 20, 48, 60);
ctx.fillStyle = '#F2B870';
ctx.fill();
el(CX + HEAD_RX - 12, HEAD_CY + 20, 30, 40);
ctx.fillStyle = '#E09060';
ctx.fill();
ctx.restore();

// ── Chubby cheeks ────────────────────────────────────────
ctx.save();
el(CX - 145, HEAD_CY + 90, 88, 62);
ctx.fillStyle = 'rgba(235,110,90,0.30)';
ctx.fill();
el(CX + 145, HEAD_CY + 90, 88, 62);
ctx.fillStyle = 'rgba(235,110,90,0.30)';
ctx.fill();
// cheek shine dots
el(CX - 148, HEAD_CY + 75, 18, 12);
ctx.fillStyle = 'rgba(255,200,190,0.45)';
ctx.fill();
el(CX + 148, HEAD_CY + 75, 18, 12);
ctx.fillStyle = 'rgba(255,200,190,0.45)';
ctx.fill();
ctx.restore();

// ── Eyes ────────────────────────────────────────────────
const EY = HEAD_CY - 35;
ctx.save();
// whites
el(CX - 72, EY, 50, 44);
ctx.fillStyle = '#FFFFFF';
ctx.fill();
el(CX + 72, EY, 50, 44);
ctx.fillStyle = '#FFFFFF';
ctx.fill();
// irises (warm brown)
el(CX - 68, EY + 2, 32, 32);
ctx.fillStyle = '#6B4220';
ctx.fill();
el(CX + 68, EY + 2, 32, 32);
ctx.fillStyle = '#6B4220';
ctx.fill();
// pupils
el(CX - 65, EY + 3, 17, 18);
ctx.fillStyle = '#180800';
ctx.fill();
el(CX + 65, EY + 3, 17, 18);
ctx.fillStyle = '#180800';
ctx.fill();
// shine
el(CX - 58, EY - 5, 8, 8);
ctx.fillStyle = 'rgba(255,255,255,0.9)';
ctx.fill();
el(CX + 58, EY - 5, 8, 8);
ctx.fillStyle = 'rgba(255,255,255,0.9)';
ctx.fill();
// squint lines (happy eyes)
ctx.strokeStyle = 'rgba(100,50,10,0.4)';
ctx.lineWidth = 4;
ctx.lineCap = 'round';
// top eyelid slight curve
ctx.beginPath();
ctx.moveTo(CX - 120, EY - 16);
ctx.quadraticCurveTo(CX - 70, EY - 46, CX - 20, EY - 16);
ctx.stroke();
ctx.beginPath();
ctx.moveTo(CX + 20, EY - 16);
ctx.quadraticCurveTo(CX + 70, EY - 46, CX + 120, EY - 16);
ctx.stroke();
ctx.restore();

// ── Eyebrows (raised, friendly) ──────────────────────────
ctx.save();
ctx.lineWidth = 16;
ctx.lineCap = 'round';
ctx.strokeStyle = '#3C2010';
ctx.beginPath();
ctx.moveTo(CX - 118, EY - 65);
ctx.quadraticCurveTo(CX - 70, EY - 82, CX - 22, EY - 65);
ctx.stroke();
ctx.beginPath();
ctx.moveTo(CX + 22, EY - 65);
ctx.quadraticCurveTo(CX + 70, EY - 82, CX + 118, EY - 65);
ctx.stroke();
ctx.restore();

// ── Nose (round, bulbous) ────────────────────────────────
ctx.save();
el(CX, HEAD_CY + 55, 34, 27);
const ng = ctx.createRadialGradient(CX - 8, HEAD_CY + 48, 4, CX, HEAD_CY + 55, 34);
ng.addColorStop(0, '#F5C080');
ng.addColorStop(1, '#D08050');
ctx.fillStyle = ng;
ctx.fill();
// nostrils
el(CX - 14, HEAD_CY + 65, 10, 8);
ctx.fillStyle = '#B06040';
ctx.fill();
el(CX + 14, HEAD_CY + 65, 10, 8);
ctx.fillStyle = '#B06040';
ctx.fill();
ctx.restore();

// ── HUGE WHITE MUSTACHE ──────────────────────────────────
const MY = HEAD_CY + 78;
ctx.save();
const mg = ctx.createRadialGradient(CX, MY, 5, CX, MY, 155);
mg.addColorStop(0, '#FFFFFF');
mg.addColorStop(0.7, '#EEECE0');
mg.addColorStop(1, '#D0CEC0');
// left puff (big and fluffy)
ctx.beginPath();
ctx.ellipse(CX - 82, MY - 2, 100, 60, -0.10, 0, Math.PI * 2);
ctx.fillStyle = mg;
ctx.fill();
ctx.strokeStyle = '#C8C4B0';
ctx.lineWidth = 2.5;
ctx.stroke();
// right puff
ctx.beginPath();
ctx.ellipse(CX + 82, MY - 2, 100, 60, 0.10, 0, Math.PI * 2);
ctx.fillStyle = mg;
ctx.fill();
ctx.strokeStyle = '#C8C4B0';
ctx.lineWidth = 2.5;
ctx.stroke();
// center overlap
el(CX, MY - 5, 45, 35);
ctx.fillStyle = '#F4F2EA';
ctx.fill();
// strands highlight
ctx.strokeStyle = 'rgba(255,255,255,0.7)';
ctx.lineWidth = 5;
ctx.lineCap = 'round';
ctx.beginPath();
ctx.moveTo(CX - 170, MY - 8);
ctx.quadraticCurveTo(CX - 120, MY - 26, CX - 70, MY - 10);
ctx.stroke();
ctx.beginPath();
ctx.moveTo(CX + 70, MY - 10);
ctx.quadraticCurveTo(CX + 120, MY - 26, CX + 170, MY - 8);
ctx.stroke();
// curl tips
ctx.strokeStyle = 'rgba(200,195,180,0.6)';
ctx.lineWidth = 4;
ctx.beginPath();
ctx.moveTo(CX - 175, MY - 5);
ctx.quadraticCurveTo(CX - 195, MY + 15, CX - 178, MY + 30);
ctx.stroke();
ctx.beginPath();
ctx.moveTo(CX + 175, MY - 5);
ctx.quadraticCurveTo(CX + 195, MY + 15, CX + 178, MY + 30);
ctx.stroke();
ctx.restore();

// ── Big happy smile (below mustache) ────────────────────
ctx.save();
const SMILE_CY = HEAD_CY + 155;
// teeth
ctx.beginPath();
ctx.arc(CX, SMILE_CY, 68, 0.05 * Math.PI, 0.95 * Math.PI);
ctx.fillStyle = '#FFFFFF';
ctx.fill();
// mouth outline
ctx.beginPath();
ctx.arc(CX, SMILE_CY, 68, 0.05 * Math.PI, 0.95 * Math.PI);
ctx.strokeStyle = '#7A3A18';
ctx.lineWidth = 7;
ctx.stroke();
// upper lip line
ctx.beginPath();
ctx.moveTo(CX - 68, SMILE_CY);
ctx.lineTo(CX + 68, SMILE_CY);
ctx.strokeStyle = 'rgba(160,100,60,0.3)';
ctx.lineWidth = 3;
ctx.stroke();
// center tooth gap
ctx.beginPath();
ctx.moveTo(CX, SMILE_CY + 2);
ctx.lineTo(CX, SMILE_CY + 60);
ctx.strokeStyle = 'rgba(180,140,100,0.35)';
ctx.lineWidth = 4;
ctx.stroke();
ctx.restore();

// ────────────────────────────────────────────────────────
// TOP HAT (compact, sits on head)
// Hat bottom (brim) at HEAD_CY - HEAD_RY + 60 = ~320
const HAT_BRIM_Y = HEAD_CY - HEAD_RY + 55; // ~415 → brim sits on top of head
const HAT_BODY_H = 210;
const HAT_BRIM_RX = 240;

// hat drop shadow
ctx.save();
el(CX + 10, HAT_BRIM_Y + 14, HAT_BRIM_RX, 46);
ctx.fillStyle = 'rgba(0,0,0,0.20)';
ctx.fill();
ctx.restore();

// brim
ctx.save();
el(CX, HAT_BRIM_Y, HAT_BRIM_RX, 42);
const brimG = ctx.createLinearGradient(CX - HAT_BRIM_RX, HAT_BRIM_Y, CX + HAT_BRIM_RX, HAT_BRIM_Y + 20);
brimG.addColorStop(0, '#252525');
brimG.addColorStop(0.35, '#484848');
brimG.addColorStop(0.65, '#363636');
brimG.addColorStop(1, '#181818');
ctx.fillStyle = brimG;
ctx.fill();
ctx.restore();

// hat body (cylinder)
const HT = HAT_BRIM_Y - HAT_BODY_H; // top y
const HW = 155; // half-width
ctx.save();
ctx.beginPath();
ctx.rect(CX - HW, HT, HW * 2, HAT_BODY_H);
const hatG = ctx.createLinearGradient(CX - HW, 0, CX + HW, 0);
hatG.addColorStop(0, '#181818');
hatG.addColorStop(0.28, '#383838');
hatG.addColorStop(0.55, '#2C2C2C');
hatG.addColorStop(1, '#101010');
ctx.fillStyle = hatG;
ctx.fill();
ctx.restore();

// hat top ellipse
ctx.save();
el(CX, HT, HW, 25);
ctx.fillStyle = '#202020';
ctx.fill();
ctx.restore();

// gold band
const BAND_H = 40;
const BAND_Y = HAT_BRIM_Y - BAND_H - 4;
ctx.save();
ctx.beginPath();
ctx.rect(CX - HW - 2, BAND_Y, (HW + 2) * 2, BAND_H);
const bandG = ctx.createLinearGradient(CX - HW, BAND_Y, CX + HW, BAND_Y + BAND_H);
bandG.addColorStop(0, '#7A5408');
bandG.addColorStop(0.2, '#F0CC50');
bandG.addColorStop(0.5, '#C59B20');
bandG.addColorStop(0.8, '#EEC840');
bandG.addColorStop(1, '#7A5408');
ctx.fillStyle = bandG;
ctx.fill();
ctx.restore();

// hat highlight streak
ctx.save();
ctx.beginPath();
ctx.rect(CX - HW + 10, HT + 8, 52, HAT_BODY_H - 48);
ctx.fillStyle = 'rgba(255,255,255,0.07)';
ctx.fill();
ctx.restore();

// coin emblem on band
ctx.save();
el(CX, BAND_Y + BAND_H / 2, 24, 24);
ctx.fillStyle = '#F5D060';
ctx.fill();
el(CX, BAND_Y + BAND_H / 2, 17, 17);
ctx.fillStyle = '#B88C10';
ctx.fill();
ctx.font = 'bold 18px serif';
ctx.fillStyle = '#F5E080';
ctx.textAlign = 'center';
ctx.textBaseline = 'middle';
ctx.fillText('¥', CX, BAND_Y + BAND_H / 2 + 1);
ctx.restore();

// ── Clip to rounded-square ───────────────────────────────
ctx.globalCompositeOperation = 'destination-in';
roundRect(0, 0, SIZE, SIZE, 170);
ctx.fillStyle = '#000';
ctx.fill();

// Write
const outPath = 'C:/Users/sshuser/money-app/assets/icon.png';
fs.writeFileSync(outPath, canvas.toBuffer('image/png'));
console.log('icon written:', outPath);
