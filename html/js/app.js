/* ─── State ──────────────────────────────────── */
let employees    = [];
let grades       = {};
let bossGrade    = 3;

/* ─── NUI Message Listener ───────────────────── */
window.addEventListener('message', (e) => {
  const { action, data, jobLabel, vehicles } = e.data;

  switch (action) {

    case 'openBossMenu':
      document.getElementById('jobLabel').textContent = (jobLabel || 'Boss') + ' — Management';
      employees = data.employees || [];
      grades    = data.grades    || {};
      bossGrade = data.bossGrade ?? 3;
      document.getElementById('societyBalance').textContent = '$' + (data.society || 0).toLocaleString();
      renderEmployees(employees);
      switchTab('employees');
      show('bossMenu');
      break;

    case 'openGarage':
      renderVehicles(vehicles || []);
      show('garageMenu');
      break;

    case 'closeUI':
      hideAll();
      break;
  }
});

/* ─── Panels ─────────────────────────────────── */
function show(id) {
  hideAll();
  document.getElementById(id).classList.remove('hidden');
}

function hideAll() {
  document.querySelectorAll('.panel').forEach(p => p.classList.add('hidden'));
}

function closeUI() {
  hideAll();
  fetch(`https://${GetParentResourceName()}/closeUI`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  });
}

/* ─── Tabs ───────────────────────────────────── */
function switchTab(name) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
  const activeTab = document.querySelector(`[onclick="switchTab('${name}')"]`);
  const activeContent = document.getElementById('tab-' + name);
  if (activeTab)    activeTab.classList.add('active');
  if (activeContent) activeContent.classList.add('active');
}

/* ─── Employee List ──────────────────────────── */
function renderEmployees(list) {
  const container = document.getElementById('employeeList');
  container.innerHTML = '';

  if (!list.length) {
    container.innerHTML = '<p style="color:#64748b;font-size:13px;text-align:center;padding:20px 0">No employees found.</p>';
    return;
  }

  list.forEach(emp => {
    const isBoss = parseInt(emp.grade) >= bossGrade;
    const card   = document.createElement('div');
    card.className = 'employee-card';
    card.innerHTML = `
      <div class="emp-info">
        <div class="emp-name">${escHtml(emp.firstname)} ${escHtml(emp.lastname)}</div>
        <div class="emp-grade">Grade ${emp.grade} — ${escHtml(emp.grade_label || 'Unknown')}</div>
      </div>
      <div class="emp-actions">
        ${isBoss ? '<span class="badge boss">Boss</span>' : '<span class="badge">Employee</span>'}
        <select class="grade-select" id="grade_${escHtml(emp.identifier)}">
          ${Object.keys(grades).map(g => `<option value="${g}" ${g == emp.grade ? 'selected' : ''}>${g}</option>`).join('')}
        </select>
        <button class="btn btn-warn btn-sm" onclick="setGrade('${escHtml(emp.identifier)}')">Set</button>
        <button class="btn btn-danger btn-sm" onclick="fireEmployee('${escHtml(emp.identifier)}')">Fire</button>
      </div>`;
    container.appendChild(card);
  });
}

function filterEmployees() {
  const q    = document.getElementById('empSearch').value.toLowerCase();
  const filtered = employees.filter(e =>
    (e.firstname + ' ' + e.lastname).toLowerCase().includes(q) ||
    String(e.identifier).toLowerCase().includes(q)
  );
  renderEmployees(filtered);
}

/* ─── Boss Actions ───────────────────────────── */
function setGrade(citizenid) {
  const grade = parseInt(document.getElementById('grade_' + citizenid)?.value);
  if (isNaN(grade)) return;
  post('setPlayerGrade', { citizenid, grade });
}

function fireEmployee(citizenid) {
  if (!confirm('Fire this employee?')) return;
  post('fireEmployee', { citizenid });
}

function hireEmployee() {
  const citizenid = document.getElementById('hireCitizenId').value.trim();
  if (!citizenid) return;
  post('hireEmployee', { citizenid });
  document.getElementById('hireCitizenId').value = '';
}

/* ─── Society ────────────────────────────────── */
function societyWithdraw() {
  const amount = parseInt(document.getElementById('withdrawAmt').value);
  if (!amount || amount <= 0) return;
  post('societyWithdraw', { amount });
  document.getElementById('withdrawAmt').value = '';
}

function societyDeposit() {
  const amount = parseInt(document.getElementById('depositAmt').value);
  if (!amount || amount <= 0) return;
  post('societyDeposit', { amount });
  document.getElementById('depositAmt').value = '';
}

/* ─── Vehicle Garage ─────────────────────────── */
function renderVehicles(vehicles) {
  const grid = document.getElementById('vehicleList');
  grid.innerHTML = '';

  if (!vehicles.length) {
    grid.innerHTML = '<p style="color:#64748b;font-size:13px;text-align:center;grid-column:1/-1;padding:20px 0">No vehicles available.</p>';
    return;
  }

  vehicles.forEach(v => {
    const card = document.createElement('div');
    card.className = 'vehicle-card';
    card.innerHTML = `
      <div class="vehicle-icon">🚗</div>
      <div class="vehicle-name">${escHtml(v.label)}</div>
      <div class="vehicle-price">${v.price > 0 ? '$' + v.price.toLocaleString() : 'Free'}</div>
      <button class="btn btn-primary btn-sm" onclick="spawnVehicle('${escHtml(v.model)}')">Spawn</button>`;
    grid.appendChild(card);
  });
}

function spawnVehicle(model) {
  post('spawnVehicle', { model });
  closeUI();
}

/* ─── NUI Post Helper ────────────────────────── */
function post(event, data = {}) {
  fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
}

/* ─── Escape HTML ────────────────────────────── */
function escHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/* ─── Keyboard ───────────────────────────────── */
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeUI();
});
