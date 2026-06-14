import api from "./api";

export const getStats =
  async () => {
    const response =
      await api.get(
        "/admin/dashboard/stats"
      );

    return response.data;
  };