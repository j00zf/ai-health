"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function DashboardPage() {
  const router = useRouter();

  const [admin, setAdmin] =
    useState<any>(null);

  useEffect(() => {
    const token =
      localStorage.getItem("token");

    if (!token) {
      router.push("/login");
      return;
    }

    const adminData =
      localStorage.getItem("admin");

    if (adminData) {
      setAdmin(
        JSON.parse(adminData)
      );
    }
  }, [router]);

  const logout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("admin");

    router.push("/login");
  };

  return (
    <div className="min-h-screen p-8">
      <div className="flex justify-between mb-8">
        <h1 className="text-3xl font-bold">
          Dashboard
        </h1>

        <button
          onClick={logout}
          className="bg-red-500 text-white px-4 py-2 rounded"
        >
          Logout
        </button>
      </div>

      <div className="mb-8">
        <h2 className="text-xl">
          Welcome,
          {" "}
          {admin?.name}
        </h2>

        <p>{admin?.email}</p>
      </div>

      <div className="grid md:grid-cols-4 gap-4">
        <div className="border p-6 rounded-lg">
          <h3>Total Users</h3>
          <p className="text-3xl font-bold">
            0
          </p>
        </div>

        <div className="border p-6 rounded-lg">
          <h3>Fitbit Accounts</h3>
          <p className="text-3xl font-bold">
            0
          </p>
        </div>

        <div className="border p-6 rounded-lg">
          <h3>Health Records</h3>
          <p className="text-3xl font-bold">
            0
          </p>
        </div>

        <div className="border p-6 rounded-lg">
          <h3>AI Predictions</h3>
          <p className="text-3xl font-bold">
            0
          </p>
        </div>
      </div>
    </div>
  );
}