
function parseDateToSql(dateStr) {
  if (!dateStr) return null;
  const s = String(dateStr).trim();

 
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
  
  const dmy = /^\s*(\d{1,2})\/(\d{1,2})\/(\d{4})\s*$/.exec(s);
  if (dmy) {
    const day = dmy[1].padStart(2, '0');
    const month = dmy[2].padStart(2, '0');
    const year = dmy[3];
    return `${year}-${month}-${day}`;
  }

  // Try JS Date parsing as a last resort
  const parsed = new Date(s);
  if (!isNaN(parsed.getTime())) {
    return parsed.toISOString().split('T')[0];
  }

  // Couldn't parse
  return null;
}

function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function isValidPassword(password) {
  return password && password.length >= 6;
}

function getCurrentDate() {
  return new Date().toISOString().split('T')[0];
}

function getCurrentTimestamp() {
  return new Date().toISOString();
}

module.exports = {
  parseDateToSql,
  isValidEmail,
  isValidPassword,
  getCurrentDate,
  getCurrentTimestamp
};