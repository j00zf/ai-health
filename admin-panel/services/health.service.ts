import api from "./api";

export const getAllHealthRecords = async () => {
  // Evaluates to: http://localhost:5000/api/admin/health/all
  const res = await api.get("/admin/health/all");
  return res.data;
};