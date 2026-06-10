"use client";

import { useState } from "react";
import { loginAdmin } from "../../services/auth.service";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();

  const [form, setForm] = useState({
    email: "",
    password: "",
  });

  const [loading, setLoading] =
    useState(false);

  const [error, setError] =
    useState("");

  const [success, setSuccess] =
    useState("");

  const handleSubmit = async (
    e: React.FormEvent
  ) => {
    e.preventDefault();

    setError("");
    setSuccess("");
    setLoading(true);

    try {
      console.log(
        "Submitting Login:",
        form
      );

      const response =
        await loginAdmin(form);

      console.log(
        "Login Response:",
        response.data
      );

      localStorage.setItem(
        "token",
        response.data.token
      );

      localStorage.setItem(
        "admin",
        JSON.stringify(
          response.data.admin
        )
      );

      setSuccess(
        "Login Successful. Redirecting..."
      );

      setTimeout(() => {
        router.push("/dashboard");
      }, 1000);

    } catch (err: any) {
      console.error(
        "Login Error:",
        err
      );

      const message =
        err?.response?.data?.message ||
        err?.message ||
        "Login Failed";

      setError(message);

    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-md bg-white p-8 rounded-lg shadow-lg"
      >
        <h1 className="text-3xl font-bold mb-6 text-center">
          Admin Login
        </h1>

        {error && (
          <div className="mb-4 p-3 rounded bg-red-100 text-red-700 border border-red-300">
            {error}
          </div>
        )}

        {success && (
          <div className="mb-4 p-3 rounded bg-green-100 text-green-700 border border-green-300">
            {success}
          </div>
        )}

        <input
          type="email"
          placeholder="Email"
          className="w-full border p-3 mb-4 rounded"
          value={form.email}
          onChange={(e) =>
            setForm({
              ...form,
              email: e.target.value,
            })
          }
          required
        />

        <input
          type="password"
          placeholder="Password"
          className="w-full border p-3 mb-4 rounded"
          value={form.password}
          onChange={(e) =>
            setForm({
              ...form,
              password: e.target.value,
            })
          }
          required
        />

        <button
          type="submit"
          disabled={loading}
          className={`w-full p-3 rounded text-white ${
            loading
              ? "bg-gray-500"
              : "bg-black"
          }`}
        >
          {loading
            ? "Logging In..."
            : "Login"}
        </button>

        <div className="mt-4 text-sm text-gray-500">
          <strong>Debug:</strong>
          <br />
          API: http://localhost:5000/api/auth/login
        </div>
      </form>
    </div>
  );
}