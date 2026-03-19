// middleware/upload.js

const multer = require('multer');
const path   = require('path');
const fs     = require('fs');

// Ensure the uploads folder exists
const uploadDir = path.join(__dirname, '..', 'uploads', 'profile_pictures');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const unique = `profile-${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const ext    = path.extname(file.originalname).toLowerCase() || '.jpg';
    cb(null, unique + ext);
  },
});

const fileFilter = (_req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/webp'];
  if (allowed.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only JPEG, PNG and WebP images are allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
});

// ── requirePhoto ─────────────────────────────────────────────────────────────
// Middleware to run AFTER upload.single() that rejects the request
// if no file was included. This enforces the mandatory photo rule
// at the backend level so it cannot be bypassed (e.g. via Postman).
const requirePhoto = (req, res, next) => {
  if (!req.file) {
    return res.status(400).json({
      success: false,
      message: 'A profile photo is required for registration',
    });
  }
  next();
};

module.exports = { upload, requirePhoto };