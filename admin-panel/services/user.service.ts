import api from "./api";

export const getUsers = async () => {
  const res = await api.get("/users/all");
  return res.data;
};

export const getUserHealthRecords = async (userId: string) => {
  const res = await api.get(`/users/${userId}/records`);
  return res.data;
};