const crypto = require("crypto");
const HealthRecord = require("../models/HealthRecord");
const UserProfile = require("../models/UserProfile");
const HealthSyncPoint = require("../models/HealthSyncPoint");

const NUMERIC_FIELDS = [
  "steps",
  "distanceWalked",
  "calories",
  "activeHours",
  "floors",
  "activeZoneMinutes",
  "heartRate",
  "restingHeartRate",
  "sleepHours",
  "bloodOxygen",
  "bodyTemperature",
  "weight",
];

const normalizeRecord = (record) => {
  const out = {};
  NUMERIC_FIELDS.forEach((field) => {
    const value = Number(record?.[field]);
    out[field] = Number.isFinite(value) ? value : 0;
  });

  out.date = String(record?.date || "").slice(0, 10);
  out.source = record?.source || "Google Health Cloud API";
  out.syncedAt = record?.syncedAt ? new Date(record.syncedAt) : new Date();
  out.recordHash = record?.recordHash || makeRecordHash(out);
  return out;
};

const makeRecordHash = (record) => {
  const payload = NUMERIC_FIELDS.reduce((obj, field) => {
    obj[field] = Number(record?.[field]) || 0;
    return obj;
  }, { date: String(record?.date || "").slice(0, 10) });
  return crypto.createHash("sha256").update(JSON.stringify(payload)).digest("hex");
};

const normalizeSyncPoints = (points = {}) => ({
  lastFullSyncAt: points.lastFullSyncAt ? new Date(points.lastFullSyncAt) : null,
  lastDailySyncAt: points.lastDailySyncAt ? new Date(points.lastDailySyncAt) : null,
  lastWeeklySyncAt: points.lastWeeklySyncAt ? new Date(points.lastWeeklySyncAt) : null,
  lastMonthlySyncAt: points.lastMonthlySyncAt ? new Date(points.lastMonthlySyncAt) : null,
  lastSyncAt: points.lastSyncAt ? new Date(points.lastSyncAt) : null,
  lastSyncRangeDays: Number(points.lastSyncRangeDays) || 0,
});

const nonZeroAverage = (records, field) => {
  const values = records
    .map((r) => Number(r[field]))
    .filter((v) => Number.isFinite(v) && v > 0);

  return values.length
    ? values.reduce((sum, v) => sum + v, 0) / values.length
    : 0;
};

const buildAverages = (records) => ({
  days: records.length,
  steps: nonZeroAverage(records, "steps"),
  distanceWalked: nonZeroAverage(records, "distanceWalked"),
  calories: nonZeroAverage(records, "calories"),
  activeHours: nonZeroAverage(records, "activeHours"),
  floors: nonZeroAverage(records, "floors"),
  activeZoneMinutes: nonZeroAverage(records, "activeZoneMinutes"),
  heartRate: nonZeroAverage(records, "heartRate"),
  restingHeartRate: nonZeroAverage(records, "restingHeartRate"),
  sleepHours: nonZeroAverage(records, "sleepHours"),
  bloodOxygen: nonZeroAverage(records, "bloodOxygen"),
  bodyTemperature: nonZeroAverage(records, "bodyTemperature"),
  weight: nonZeroAverage(records, "weight"),
});

// ================================
// Sync / Upsert today's health data
// ================================
exports.syncHealth = async (req, res) => {
  try {
    const normalized = normalizeRecord(req.body);

    if (!normalized.date) {
      return res.status(400).json({
        success: false,
        message: "A valid health record date is required",
      });
    }

    const record = await HealthRecord.findOneAndUpdate(
      { userId: req.user.id, date: normalized.date },
      {
        userId: req.user.id,
        ...normalized,
      },
      {
        upsert: true,
        new: true,
        runValidators: true,
      }
    );

    await UserProfile.findOneAndUpdate(
      { userId: req.user.id },
      { healthConnected: true },
      { upsert: true }
    );

    res.status(200).json({
      success: true,
      message: "Health data synced successfully",
      record,
    });
  } catch (error) {
    console.error("Health Sync Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ============================================
// Sync complete Google Health history in chunks
// ============================================
exports.syncHealthBulk = async (req, res) => {
  try {
    const records = Array.isArray(req.body.records) ? req.body.records : [];

    if (!records.length) {
      return res.status(400).json({
        success: false,
        message: "records must be a non-empty array",
      });
    }

    const operations = records
      .map(normalizeRecord)
      .filter((record) => record.date)
      .map((record) => ({
        updateOne: {
          filter: { userId: req.user.id, date: record.date },
          update: {
            $set: {
              userId: req.user.id,
              ...record,
            },
          },
          upsert: true,
        },
      }));

    if (operations.length) {
      await HealthRecord.bulkWrite(operations, { ordered: false });
    }

    await UserProfile.findOneAndUpdate(
      { userId: req.user.id },
      { healthConnected: true },
      { upsert: true }
    );

    res.status(200).json({
      success: true,
      message: "Health history synced successfully",
      synced: operations.length,
    });
  } catch (error) {
    console.error("Bulk Health Sync Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ============================================
// Cached snapshot + incremental sync points
// ============================================
exports.getHealthSnapshot = async (req, res) => {
  try {
    const [records, syncPoint] = await Promise.all([
      HealthRecord.find({ userId: req.user.id }).sort({ date: -1 }).lean(),
      HealthSyncPoint.findOne({ userId: req.user.id }).lean(),
    ]);

    res.status(200).json({
      success: true,
      data: records,
      syncPoints: syncPoint || {},
      source: "Pulse AI MongoDB cache",
    });
  } catch (error) {
    console.error("Health Snapshot Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateHealthSyncPoints = async (req, res) => {
  try {
    const points = normalizeSyncPoints(req.body?.syncPoints || {});
    const syncPoint = await HealthSyncPoint.findOneAndUpdate(
      { userId: req.user.id },
      { $set: { userId: req.user.id, ...points } },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    ).lean();

    res.status(200).json({ success: true, syncPoints: syncPoint });
  } catch (error) {
    console.error("Sync Point Update Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.syncHealthIncremental = async (req, res) => {
  try {
    const incoming = Array.isArray(req.body?.records) ? req.body.records : [];
    const normalized = incoming.map(normalizeRecord).filter((r) => r.date);
    const dates = normalized.map((r) => r.date);
    const existing = dates.length
      ? await HealthRecord.find({ userId: req.user.id, date: { $in: dates } }).lean()
      : [];
    const existingByDate = new Map(existing.map((r) => [r.date, r]));

    const changed = [];
    let inserted = 0;
    let updated = 0;

    for (const record of normalized) {
      const old = existingByDate.get(record.date);
      if (!old) {
        inserted++;
        changed.push(record);
      } else if (old.recordHash !== record.recordHash) {
        updated++;
        changed.push(record);
      }
    }

    if (changed.length) {
      await HealthRecord.bulkWrite(
        changed.map((record) => ({
          updateOne: {
            filter: { userId: req.user.id, date: record.date },
            update: { $set: { userId: req.user.id, ...record } },
            upsert: true,
          },
        })),
        { ordered: false }
      );
    }

    const syncPoint = await HealthSyncPoint.findOneAndUpdate(
      { userId: req.user.id },
      {
        $set: {
          userId: req.user.id,
          ...normalizeSyncPoints(req.body?.syncPoints || {}),
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    ).lean();

    await UserProfile.findOneAndUpdate(
      { userId: req.user.id },
      { healthConnected: true },
      { upsert: true }
    );

    res.status(200).json({
      success: true,
      inserted,
      updated,
      changed: changed.length,
      syncPoints: syncPoint,
    });
  } catch (error) {
    console.error("Incremental Health Sync Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ================================
// Get Latest Health Record
// ================================
exports.getLatestHealth = async (req, res) => {
  try {
    const latestRecord = await HealthRecord.findOne({
      userId: req.user.id,
    }).sort({ date: -1 });

    if (!latestRecord) {
      return res.status(404).json({
        success: false,
        message: "No health records found",
      });
    }

    res.status(200).json({ success: true, data: latestRecord });
  } catch (error) {
    console.error("Fetch Latest Health Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ============================================
// Get recent Health History
// ============================================
exports.getHealthHistory = async (req, res) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 30, 365);
    const records = await HealthRecord.find({ userId: req.user.id })
      .sort({ date: -1 })
      .limit(limit);

    res.status(200).json({
      success: true,
      count: records.length,
      data: records,
    });
  } catch (error) {
    console.error("Fetch Health History Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ============================================
// Get ALL records — all-time, paginated
// ============================================
exports.getAllHealthRecords = async (req, res) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 365, 1000);
    const page = Math.max(Number(req.query.page) || 1, 1);
    const skip = (page - 1) * limit;

    const [records, total] = await Promise.all([
      HealthRecord.find({ userId: req.user.id })
        .sort({ date: -1 })
        .skip(skip)
        .limit(limit),
      HealthRecord.countDocuments({ userId: req.user.id }),
    ]);

    res.status(200).json({
      success: true,
      count: records.length,
      total,
      page,
      pages: Math.max(Math.ceil(total / limit), 1),
      data: records,
    });
  } catch (error) {
    console.error("Fetch All Health Records Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ============================================
// Weekly / monthly / all-time averages
// ============================================
exports.getHealthAverages = async (req, res) => {
  try {
    const records = await HealthRecord.find({ userId: req.user.id })
      .sort({ date: 1 })
      .lean();

    const weekly = {};
    const monthly = {};

    const getIsoWeekKey = (dateString) => {
      const d = new Date(`${dateString}T12:00:00Z`);
      const day = d.getUTCDay() || 7;
      d.setUTCDate(d.getUTCDate() + 4 - day);
      const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
      const week = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
      return `${d.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
    };

    const add = (group, key, record) => {
      if (!group[key]) group[key] = [];
      group[key].push(record);
    };

    records.forEach((record) => {
      const date = String(record.date);
      add(weekly, getIsoWeekKey(date), record);
      add( monthly, date.slice(0, 7), record);
    });

    const summarize = (group) =>
      Object.entries(group)
        .map(([period, rows]) => ({
          period,
          ...buildAverages(rows),
        }))
        .sort((a, b) => b.period.localeCompare(a.period));

    res.status(200).json({
      success: true,
      allTime: buildAverages(records),
      weekly: summarize(weekly),
      monthly: summarize(monthly),
      rangeStart: records[0]?.date || null,
      rangeEnd: records[records.length - 1]?.date || null,
    });
  } catch (error) {
    console.error("Health Averages Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ================================
// Get a single record by date
// ================================
exports.getHealthRecordByDate = async (req, res) => {
  try {
    const { date } = req.params;

    const record =
      date === "latest"
        ? await HealthRecord.findOne({ userId: req.user.id }).sort({ date: -1 })
        : await HealthRecord.findOne({ userId: req.user.id, date });

    if (!record) {
      return res.status(404).json({
        success: false,
        message: "No health record found for this date",
      });
    }

    res.status(200).json({ success: true, data: record });
  } catch (error) {
    console.error("Fetch Health Record Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ================================
// Delete a record by its Mongo _id
// ================================
exports.deleteHealthRecord = async (req, res) => {
  try {
    const { id } = req.params;

    const record = await HealthRecord.findOneAndDelete({
      _id: id,
      userId: req.user.id,
    });

    if (!record) {
      return res.status(404).json({
        success: false,
        message: "Record not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Health record deleted",
    });
  } catch (error) {
    console.error("Delete Health Record Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};
