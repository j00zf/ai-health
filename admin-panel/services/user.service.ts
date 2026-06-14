import api from "./api";

export const getUsers =
  async () => {
    const res =
      await api.get(
        "/users/all"
      );

    return res.data;
  };