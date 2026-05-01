const { createCanvas } = require('canvas');
const fs = require('fs');

const W = 1080, H = 1920;
const GOLD = '#C59B63';
const GOLD2 = '#D4AA72';
const BG = '#111111';
const CARD = '#1C1C1E';
const CARD2 = '#2C2C2E';
const TEXT = '#E5E5E7';
const TEXT2 = '#8E8E93';
const GREEN = '#30D158';
const RED = '#FF453A';
const BLUE = '#0A84FF';

function newCanvas() {
  const c = createCanvas(W, H);
  const ctx = c.getContext('2d');
  ctx.fillStyle = BG;
  ctx.fillRect(0, 0, W, H);
  return { c, ctx };
}

function phoneFrame(ctx) {
  // Status bar
  ctx.fillStyle = BG;
  ctx.fillRect(0, 0, W, 90);
  ctx.fillStyle = TEXT2;
  ctx.font = 'bold 34px sans-serif';
  ctx.textAlign = 'left';
  ctx.textBaseline = 'middle';
  ctx.fillText('9:41', 60, 45);
  ctx.textAlign = 'right';
  ctx.fillText('▌▌▌  ▌  🔋', W - 60, 45);
  // Bottom nav bar background
  ctx.fillStyle = CARD;
  ctx.fillRect(0, H - 160, W, 160);
}

function navBar(ctx, activeTab) {
  const tabs = ['記帳', '明細', '', '投資', '管理'];
  const positions = [108, 324, 540, 756, 972];
  tabs.forEach((label, i) => {
    if (!label) return;
    const isActive = (
      (activeTab === 0 && i === 0) ||
      (activeTab === 1 && i === 1) ||
      (activeTab === 2 && i === 3) ||
      (activeTab === 3 && i === 4)
    );
    ctx.fillStyle = isActive ? GOLD : TEXT2;
    ctx.font = '28px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(label, positions[i], H - 80);
  });
  // FAB
  const fabGrad = ctx.createRadialGradient(W/2, H-115, 0, W/2, H-115, 70);
  fabGrad.addColorStop(0, GOLD2);
  fabGrad.addColorStop(1, GOLD);
  ctx.fillStyle = fabGrad;
  ctx.beginPath();
  ctx.arc(W/2, H - 115, 68, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#000';
  ctx.font = 'bold 60px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('+', W/2, H - 115);
}

function card(ctx, x, y, w, h, radius = 22) {
  ctx.fillStyle = CARD;
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, radius);
  ctx.fill();
}

function goldLabel(ctx, text, x, y, size = 26) {
  ctx.fillStyle = GOLD;
  ctx.font = `600 ${size}px sans-serif`;
  ctx.textAlign = 'left';
  ctx.textBaseline = 'top';
  ctx.fillText(text, x, y);
}

function caption(ctx, text) {
  const grad = ctx.createLinearGradient(0, H - 300, 0, H - 160);
  grad.addColorStop(0, 'rgba(17,17,17,0)');
  grad.addColorStop(0.4, 'rgba(17,17,17,0.95)');
  grad.addColorStop(1, 'rgba(17,17,17,0.95)');
  ctx.fillStyle = grad;
  ctx.fillRect(0, H - 300, W, 140);
  ctx.fillStyle = TEXT;
  ctx.font = 'bold 46px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, W / 2, H - 215);
}

// ─── Screenshot 1: 記帳總覽 ─────────────────────────────────────────────────
function shot1() {
  const { c, ctx } = newCanvas();
  phoneFrame(ctx);

  // App bar
  ctx.fillStyle = TEXT;
  ctx.font = 'bold 52px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('錢錢管家', W / 2, 155);
  ctx.fillStyle = TEXT2;
  ctx.font = '30px sans-serif';
  ctx.fillText('2026 年 5 月', W / 2, 205);

  // Month selector
  const months = ['3月', '4月', '5月', '6月', '7月'];
  const mw = 160, mh = 68, mx0 = (W - months.length * mw - (months.length-1)*20) / 2;
  months.forEach((m, i) => {
    const mx = mx0 + i * (mw + 20);
    ctx.fillStyle = m === '5月' ? GOLD : CARD;
    ctx.beginPath(); ctx.roundRect(mx, 250, mw, mh, 34); ctx.fill();
    ctx.fillStyle = m === '5月' ? '#000' : TEXT2;
    ctx.font = `${m === '5月' ? 'bold ' : ''}30px sans-serif`;
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText(m, mx + mw/2, 250 + mh/2);
  });

  // Budget card
  card(ctx, 50, 360, W - 100, 220);
  ctx.fillStyle = TEXT2;
  ctx.font = '30px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
  ctx.fillText('本月支出 / 預算', 90, 395);
  ctx.fillStyle = TEXT;
  ctx.font = 'bold 64px sans-serif';
  ctx.fillText('NT$ 7,090', 90, 435);
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif';
  ctx.fillText('/ NT$ 30,000', 90 + ctx.measureText('NT$ 7,090').width + 20, 455);
  // Progress bar
  const bx = 90, by = 520, bw = W - 180, bh = 18, progress = 7090 / 30000;
  ctx.fillStyle = CARD2;
  ctx.beginPath(); ctx.roundRect(bx, by, bw, bh, 9); ctx.fill();
  const barGrad = ctx.createLinearGradient(bx, 0, bx + bw * progress, 0);
  barGrad.addColorStop(0, GOLD); barGrad.addColorStop(1, GOLD2);
  ctx.fillStyle = barGrad;
  ctx.beginPath(); ctx.roundRect(bx, by, bw * progress, bh, 9); ctx.fill();
  ctx.fillStyle = GOLD; ctx.font = 'bold 28px sans-serif'; ctx.textAlign = 'right';
  ctx.fillText('剩餘 NT$ 22,910', W - 90, 555);

  // Pie chart card
  card(ctx, 50, 620, W - 100, 600);
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
  ctx.fillText('本月支出分佈', 90, 655);

  const pieData = [
    { label: '購物',   val: 2490, color: '#C48DA0' },
    { label: '餐飲',   val: 1600, color: '#D7BC74' },
    { label: '交通',   val: 1530, color: '#C59B63' },
    { label: '教育',   val:  850, color: '#7B9BB5' },
    { label: '醫療',   val:  600, color: '#88A89A' },
    { label: '娛樂',   val:  569, color: '#98AF82' },
  ];
  const total = pieData.reduce((s, d) => s + d.val, 0);
  const cx = W / 2 - 40, cy = 1010, r = 200, ir = 90;
  let angle = -Math.PI / 2;
  pieData.forEach(d => {
    const sweep = (d.val / total) * Math.PI * 2;
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.arc(cx, cy, r, angle, angle + sweep);
    ctx.closePath();
    ctx.fillStyle = d.color; ctx.fill();
    ctx.strokeStyle = BG; ctx.lineWidth = 3; ctx.stroke();
    angle += sweep;
  });
  // Donut hole
  ctx.fillStyle = CARD;
  ctx.beginPath(); ctx.arc(cx, cy, ir, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = TEXT; ctx.font = 'bold 36px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillText('NT$', cx, cy - 20); ctx.fillText('7,090', cx, cy + 22);
  // Legend
  let lx = cx + 240, ly = 810;
  pieData.forEach(d => {
    ctx.fillStyle = d.color;
    ctx.beginPath(); ctx.roundRect(lx, ly, 24, 24, 4); ctx.fill();
    ctx.fillStyle = TEXT; ctx.font = '26px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
    ctx.fillText(`${d.label}  NT$ ${d.val.toLocaleString()}`, lx + 34, ly + 12);
    ly += 52;
  });

  // Recent expenses
  card(ctx, 50, 1260, W - 100, 340);
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
  ctx.fillText('最近支出', 90, 1296);
  const recent = [
    { title: '秋季新衣', cat: '購物', amt: 2490, color: '#C48DA0' },
    { title: '家庭聚餐', cat: '餐飲', amt: 1280, color: '#D7BC74' },
    { title: '捷運月票', cat: '交通', amt: 1280, color: '#C59B63' },
  ];
  recent.forEach((e, i) => {
    const ey = 1345 + i * 80;
    ctx.fillStyle = e.color; ctx.beginPath(); ctx.arc(90, ey + 20, 14, 0, Math.PI*2); ctx.fill();
    ctx.fillStyle = TEXT; ctx.font = '30px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
    ctx.fillText(e.title, 118, ey + 20);
    ctx.fillStyle = TEXT2; ctx.textAlign = 'right';
    ctx.fillText(`NT$ ${e.amt.toLocaleString()}`, W - 90, ey + 20);
  });

  navBar(ctx, 0);
  caption(ctx, '月度預算一目了然');
  fs.writeFileSync('docs/screenshot_1_dashboard.png', c.toBuffer('image/png'));
  console.log('✓ screenshot 1');
}

// ─── Screenshot 2: 支出明細 ─────────────────────────────────────────────────
function shot2() {
  const { c, ctx } = newCanvas();
  phoneFrame(ctx);

  ctx.fillStyle = TEXT; ctx.font = 'bold 52px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
  ctx.fillText('5 月明細', 60, 160);
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif'; ctx.textAlign = 'right';
  ctx.fillText('全部分類', W - 60, 160);

  const expenses = [
    { title: '秋季新衣',    cat: '購物', amt: 2490, date: '5/10', color: '#C48DA0' },
    { title: '課程教材',    cat: '教育', amt:  850, date: '5/08', color: '#7B9BB5' },
    { title: '家庭聚餐',    cat: '餐飲', amt: 1280, date: '5/03', color: '#D7BC74' },
    { title: '捷運月票',    cat: '交通', amt: 1280, date: '5/01', color: '#C59B63' },
    { title: '健身房月費',  cat: '醫療', amt:  600, date: '5/02', color: '#88A89A' },
    { title: 'Netflix 月費',cat: '娛樂', amt:  390, date: '5/05', color: '#98AF82' },
    { title: '早午餐',      cat: '餐飲', amt:  320, date: '5/12', color: '#D7BC74' },
    { title: '計程車',      cat: '交通', amt:  250, date: '5/07', color: '#C59B63' },
  ];

  expenses.forEach((e, i) => {
    const ey = 230 + i * 170;
    card(ctx, 50, ey, W - 100, 145, 16);
    // Color dot
    ctx.fillStyle = e.color;
    ctx.beginPath(); ctx.arc(105, ey + 48, 20, 0, Math.PI*2); ctx.fill();
    // Cat label
    ctx.fillStyle = e.color + '33';
    ctx.beginPath(); ctx.roundRect(137, ey + 28, 100, 40, 20); ctx.fill();
    ctx.fillStyle = e.color; ctx.font = '24px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText(e.cat, 187, ey + 48);
    // Title
    ctx.fillStyle = TEXT; ctx.font = 'bold 36px sans-serif'; ctx.textAlign = 'left';
    ctx.fillText(e.title, 255, ey + 48);
    // Date
    ctx.fillStyle = TEXT2; ctx.font = '26px sans-serif';
    ctx.fillText(e.date, 255, ey + 98);
    // Amount
    ctx.fillStyle = TEXT; ctx.font = 'bold 38px sans-serif'; ctx.textAlign = 'right';
    ctx.fillText(`-NT$ ${e.amt.toLocaleString()}`, W - 90, ey + 70);
  });

  // Long press hint
  card(ctx, 100, 1620, W - 200, 100, 50);
  ctx.fillStyle = TEXT2; ctx.font = '28px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillText('💡 長按可編輯 · 複製 · 刪除', W/2, 1670);

  navBar(ctx, 1);
  caption(ctx, '完整支出記錄一覽');
  fs.writeFileSync('docs/screenshot_2_detail.png', c.toBuffer('image/png'));
  console.log('✓ screenshot 2');
}

// ─── Screenshot 3: 投資追蹤 ─────────────────────────────────────────────────
function shot3() {
  const { c, ctx } = newCanvas();
  phoneFrame(ctx);

  ctx.fillStyle = TEXT; ctx.font = 'bold 52px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
  ctx.fillText('投資追蹤', 60, 160);

  // Portfolio summary card
  card(ctx, 50, 210, W - 100, 300);
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'top';
  ctx.fillText('投資組合總值', W/2, 248);
  ctx.fillStyle = TEXT; ctx.font = 'bold 76px sans-serif'; ctx.textAlign = 'center';
  ctx.fillText('NT$ 79,462', W/2, 288);
  ctx.fillStyle = GREEN; ctx.font = 'bold 38px sans-serif';
  ctx.fillText('▲ NT$ 5,462  +7.4%', W/2, 375);
  // Mini bars
  const miniBar = [0.3, 0.6, 0.4, 0.7, 0.5, 0.8, 0.65];
  miniBar.forEach((h, i) => {
    const bx = W/2 - 120 + i * 38, bh = h * 60;
    ctx.fillStyle = GREEN + '66';
    ctx.beginPath(); ctx.roundRect(bx, 435, 22, -bh + 60, [4,4,0,0]); ctx.fill();
  });

  // Holdings
  const holdings = [
    { code:'2330', name:'台積電',       shares:10, cost: 7800, price:  850, currency:'TWD', gain: +662, pct: +8.5 },
    { code:'AAPL', name:'Apple Inc.',   shares: 5, cost:28000, price:  195, currency:'USD', gain:+3200, pct:+11.4 },
    { code:'0050', name:'元大台灣50',   shares:20, cost:38000, price:  205, currency:'TWD', gain:+3200, pct: +8.4 },
  ];

  holdings.forEach((h, i) => {
    const hy = 570 + i * 260;
    card(ctx, 50, hy, W - 100, 220, 18);
    // Header
    ctx.fillStyle = GOLD; ctx.font = 'bold 36px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
    ctx.fillText(h.code, 90, hy + 30);
    ctx.fillStyle = TEXT2; ctx.font = '28px sans-serif'; ctx.textBaseline = 'top';
    ctx.fillText(h.name, 90, hy + 78);
    ctx.fillStyle = TEXT2; ctx.font = '28px sans-serif'; ctx.textAlign = 'right';
    ctx.fillText(`${h.shares} 股 · ${h.currency}`, W - 90, hy + 30);
    // Price
    ctx.fillStyle = TEXT; ctx.font = 'bold 44px sans-serif'; ctx.textAlign = 'right';
    ctx.fillText(h.currency === 'TWD' ? `NT$ ${h.price}` : `$${h.price}`, W - 90, hy + 78);
    // Gain
    const gainColor = h.gain >= 0 ? GREEN : RED;
    ctx.fillStyle = gainColor; ctx.font = 'bold 34px sans-serif'; ctx.textAlign = 'left';
    ctx.fillText(`${h.gain >= 0 ? '+' : ''}NT$ ${h.gain.toLocaleString()}`, 90, hy + 148);
    ctx.textAlign = 'right';
    ctx.fillText(`${h.pct >= 0 ? '+' : ''}${h.pct}%`, W - 90, hy + 148);
    // Divider
    ctx.strokeStyle = CARD2; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(90, hy + 200); ctx.lineTo(W - 90, hy + 200); ctx.stroke();
  });

  navBar(ctx, 2);
  caption(ctx, '台股美股即時損益追蹤');
  fs.writeFileSync('docs/screenshot_3_invest.png', c.toBuffer('image/png'));
  console.log('✓ screenshot 3');
}

// ─── Screenshot 4: 帳戶管理 ─────────────────────────────────────────────────
function shot4() {
  const { c, ctx } = newCanvas();
  phoneFrame(ctx);

  ctx.fillStyle = TEXT; ctx.font = 'bold 52px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
  ctx.fillText('管理', 60, 160);

  // Net worth card
  card(ctx, 50, 210, W - 100, 300);
  const netGrad = ctx.createLinearGradient(50, 210, W - 50, 510);
  netGrad.addColorStop(0, '#1C1C1E');
  netGrad.addColorStop(1, '#2a2218');
  ctx.fillStyle = netGrad;
  ctx.beginPath(); ctx.roundRect(50, 210, W - 100, 300, 22); ctx.fill();
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'top';
  ctx.fillText('帳戶淨資產', W/2, 248);
  ctx.fillStyle = GOLD; ctx.font = 'bold 80px sans-serif'; ctx.textAlign = 'center';
  ctx.fillText('NT$ 75,700', W/2, 288);
  // breakdown
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif'; ctx.textAlign = 'left';
  ctx.fillText('儲蓄  NT$ 88,200', 90, 398);
  ctx.fillStyle = RED; ctx.textAlign = 'right';
  ctx.fillText('負債  -NT$ 12,500', W - 90, 398);

  // Accounts
  const accounts = [
    { icon: '🏦', name: '台新銀行',  type: '銀行帳戶', balance: 85000, positive: true },
    { icon: '💚', name: 'Line Pay',  type: '電子錢包', balance:  3200, positive: true },
    { icon: '💳', name: 'VISA 卡',   type: '信用卡',   balance:-12500, positive: false },
  ];
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
  ctx.fillText('我的帳戶', 60, 548);

  accounts.forEach((a, i) => {
    const ay = 590 + i * 170;
    card(ctx, 50, ay, W - 100, 145, 16);
    ctx.font = '52px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
    ctx.fillText(a.icon, 90, ay + 73);
    ctx.fillStyle = TEXT; ctx.font = 'bold 34px sans-serif';
    ctx.fillText(a.name, 168, ay + 50);
    ctx.fillStyle = TEXT2; ctx.font = '26px sans-serif';
    ctx.fillText(a.type, 168, ay + 96);
    const balColor = a.positive ? TEXT : RED;
    ctx.fillStyle = balColor; ctx.font = 'bold 36px sans-serif'; ctx.textAlign = 'right';
    ctx.fillText(`${a.positive ? '' : '-'}NT$ ${Math.abs(a.balance).toLocaleString()}`, W - 90, ay + 73);
  });

  // Fixed items
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
  ctx.fillText('固定開銷', 60, 1110);
  const fixed = [
    { title: '房租',         amt: 15000, color: '#B8956A' },
    { title: 'Spotify 訂閱', amt:   179, color: '#98AF82' },
    { title: '手機月租費',   amt:   699, color: TEXT2 },
  ];
  fixed.forEach((f, i) => {
    const fy = 1152 + i * 130;
    card(ctx, 50, fy, W - 100, 105, 14);
    ctx.fillStyle = f.color; ctx.beginPath(); ctx.arc(90, fy + 52, 14, 0, Math.PI*2); ctx.fill();
    ctx.fillStyle = TEXT; ctx.font = 'bold 32px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
    ctx.fillText(f.title, 120, fy + 52);
    ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif'; ctx.textAlign = 'right';
    ctx.fillText(`NT$ ${f.amt.toLocaleString()} / 月`, W - 90, fy + 52);
  });

  navBar(ctx, 3);
  caption(ctx, '資產負債一站管理');
  fs.writeFileSync('docs/screenshot_4_manage.png', c.toBuffer('image/png'));
  console.log('✓ screenshot 4');
}

// ─── Screenshot 5: 新手導覽 ─────────────────────────────────────────────────
function shot5() {
  const { c, ctx } = newCanvas();
  // Background: dashboard blurred
  ctx.fillStyle = BG; ctx.fillRect(0, 0, W, H);
  phoneFrame(ctx);

  // Dimmed overlay
  ctx.fillStyle = 'rgba(0,0,0,0.72)';
  ctx.fillRect(0, 0, W, H);

  // Spotlight on budget card area (clear circle)
  ctx.save();
  ctx.globalCompositeOperation = 'destination-out';
  ctx.beginPath(); ctx.roundRect(50, 540, W - 100, 220, 22); ctx.fill();
  ctx.restore();

  // Simulate budget card underneath spotlight
  ctx.fillStyle = CARD;
  ctx.beginPath(); ctx.roundRect(50, 540, W - 100, 220, 22); ctx.fill();
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
  ctx.fillText('本月支出 / 預算', 90, 576);
  ctx.fillStyle = TEXT; ctx.font = 'bold 60px sans-serif';
  ctx.fillText('NT$ 7,090', 90, 615);
  ctx.fillStyle = CARD2; ctx.beginPath(); ctx.roundRect(90, 700, W - 180, 16, 8); ctx.fill();
  const g2 = ctx.createLinearGradient(90, 0, 90 + (W-180)*0.24, 0);
  g2.addColorStop(0, GOLD); g2.addColorStop(1, GOLD2);
  ctx.fillStyle = g2; ctx.beginPath(); ctx.roundRect(90, 700, (W-180)*0.24, 16, 8); ctx.fill();
  ctx.fillStyle = GOLD; ctx.font = 'bold 28px sans-serif'; ctx.textAlign = 'right';
  ctx.fillText('剩餘 NT$ 22,910', W - 90, 730);

  // Tooltip card
  card(ctx, 80, 810, W - 160, 320, 22);
  // Golden step indicator
  ctx.fillStyle = GOLD; ctx.font = 'bold 28px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
  ctx.fillText('步驟 2 / 15', 116, 848);
  ctx.fillStyle = TEXT; ctx.font = 'bold 46px sans-serif';
  ctx.fillText('預算進度', 116, 893);
  ctx.fillStyle = TEXT2; ctx.font = '30px sans-serif';
  const bodyLines = ['顯示本月支出佔預算的比例、剩餘', '預算，以及日均建議消費額。', '可切換「含固定開銷」模式。'];
  bodyLines.forEach((l, i) => ctx.fillText(l, 116, 952 + i * 44));
  // Buttons
  ctx.fillStyle = CARD2;
  ctx.beginPath(); ctx.roundRect(116, 1076, 200, 60, 30); ctx.fill();
  ctx.fillStyle = TEXT2; ctx.font = '28px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillText('跳過', 216, 1106);
  ctx.fillStyle = GOLD;
  ctx.beginPath(); ctx.roundRect(346, 1076, 280, 60, 30); ctx.fill();
  ctx.fillStyle = '#000'; ctx.font = 'bold 28px sans-serif';
  ctx.fillText('下一步 ▶', 486, 1106);

  // Progress dots
  for (let i = 0; i < 15; i++) {
    const dx = W/2 - 7.5*24 + i*24;
    ctx.fillStyle = i === 1 ? GOLD : TEXT2 + '55';
    ctx.beginPath(); ctx.arc(dx, 1185, i === 1 ? 8 : 5, 0, Math.PI*2); ctx.fill();
  }

  // Page title (top)
  ctx.fillStyle = TEXT;
  ctx.font = 'bold 52px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillText('錢錢管家', W/2, 155);

  navBar(ctx, 0);
  caption(ctx, '15 步互動式新手導覽');
  fs.writeFileSync('docs/screenshot_5_tour.png', c.toBuffer('image/png'));
  console.log('✓ screenshot 5');
}

shot1(); shot2(); shot3(); shot4(); shot5();
console.log('\n全部完成 → docs/screenshot_1~5.png');
