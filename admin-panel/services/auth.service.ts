import api from "./api";

export const registerAdmin = async (data: {
  name: string;
  email: string;
  password: string;
}) => {
  return api.post("/auth/register", data);
};

export const loginAdmin = async (data: {
  email: string;
  password: string;
}) => {
  return api.post("/auth/login", data);
};