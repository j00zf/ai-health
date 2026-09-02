const express = require("express");
const multer = require("multer");

const router = express.Router();
const protect = require("../middleware/userAuth");
const cvController = require("../controllers/cvController");

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
  fileFilter: (req, file, cb) => {
    const allowed = ["image/jpeg", "image/png", "image/webp"];
    if (!allowed.includes(file.mimetype)) {
      return cb(new Error("Only JPEG, PNG, or WEBP images are allowed"));
    }
    cb(null, true);
  },
});

// Existing JSON-only feature endpoint.
router.post("/analyze", protect, cvController.analyze);

// New endpoint: local CV feature JSON + one real face image.
router.post(
  "/analyze-image",
  protect,
  upload.single("file"),
  cvController.analyzeWithImage
);

router.get("/latest", protect, cvController.getLatest);

// Put this before /:id so Express never treats "latest" as an id.
router.get(
  "/latest/chat-context",
  protect,
  cvController.getLatestChatContext
);

router.get("/history", protect, cvController.getHistory);
router.get("/summary", protect, cvController.getSummary);
router.get("/trends", protect, cvController.getTrends);
router.get("/:id", protect, cvController.getById);
router.delete("/:id", protect, cvController.delete);

module.exports = router;
