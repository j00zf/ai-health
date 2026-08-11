"use client";

import React, { useEffect, useState, use } from "react";
import { useRouter } from "next/navigation";
import { getUserHealthRecords } from "@/services/user.service";
import Sidebar from "@/components/Sidebar";
import {
  Activity,
  ArrowLeft,
  Calendar,
  Heart,
  Flame,
  Footprints,
  Moon,
  Thermometer,
  Loader2,
  Info,
  RefreshCw,
  Scale,
  Zap,
} from "lucide-react";

export default function UserHealthRecordsPage({
  params,
}: {
  params: Promise<{ userId: string }>;
}) {
  const resolvedParams = use(params);
  const userId = resolvedParams.userId;

  const router = useRouter();
  const [records, setRecords] = useState<any[]>([]);
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) {
      router.push("/login");
      return;
    }
    fetchRecords();
  }, [userId, router]);

  const fetchRecords = async () => {
    setLoading(true);
    try {
      const data = await getUserHealthRecords(userId);
      setRecords(data.records || []);
      setUser(data.user || null);
    } catch (error) {
      console.error("Error fetching health records:", error);
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("admin");
    router.push("/login");
  };

  return (
    <div className="min-h-screen w-full bg-[#050505] flex text-white font-sans relative overflow-hidden selection:bg-emerald-500/30 selection:text-emerald-400">
      {/* Background Matrix */}
      <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
        <div
          className="absolute inset-0 bg-[linear-gradient(to_right,#141414_1px,transparent_1px),linear-gradient(to_bottom,#141414_1px,transparent_1px)] bg-[size:45px_45px]"
          style={{
            maskImage: "radial-gradient(ellipse at center, black 30%, transparent 80%)",
            WebkitMaskImage: "radial-gradient(ellipse at center, black 30%, transparent 80%)",
          }}
        />
        <div className="absolute top-[10%] left-[40%] w-[500px] h-[500px] bg-emerald-500/[0.02] rounded-full blur-[140px] animate-pulse" />
      </div>

      <Sidebar onLogout={logout} />

      {/* Main Container */}
      <main className="flex-1 p-8 lg:p-10 z-10 overflow-y-auto w-full space-y-6 animate-[fadeIn_0.5s_ease-out_forwards]">
        {/* Navigation & Header Control Hub */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-zinc-900 pb-5">
          <div className="space-y-1">
            <button
              onClick={() => router.push("/users")}
              className="inline-flex items-center gap-1.5 text-xs text-zinc-500 hover:text-emerald-400 transition-colors font-mono mb-2 group"
            >
              <ArrowLeft size={13} className="group-hover:-translate-x-0.5 transition-transform" />
              <span>Back to Registry</span>
            </button>
            <div className="flex items-center gap-2">
              <Activity size={14} className="text-emerald-400" />
              <span className="text-[10px] font-mono tracking-[0.3em] text-zinc-500 uppercase">
                Telemetry Log Stream
              </span>
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-white bg-gradient-to-b from-white to-zinc-400 bg-clip-text text-transparent">
              {user?.name ? `${user.name}'s Health Records` : "User Telemetry Data"}
            </h1>
            {user?.email && (
              <p className="text-xs font-mono text-zinc-500">{user.email}</p>
            )}
          </div>

          <div className="flex items-center gap-3 self-end sm:self-auto">
            <button
              onClick={fetchRecords}
              disabled={loading}
              className="p-2.5 bg-zinc-900  hover:bg-slate-600  rounded-xl transition-colors disabled:opacity-40"
              title="Refresh Telemetry Matrix"
            >
              <RefreshCw
                size={14}
                className={`${loading ? "animate-spin text-emerald-400" : "text-zinc-400"}`}
              />
            </button>
            <div className="bg-zinc-950/40 border border-zinc-50 px-4 py-2 rounded-xl font-mono text-xs text-zinc-400 tracking-wider">
              TOTAL LOG NODES:{" "}
              <span className="text-emerald-400 font-bold ml-1">
                {loading ? "..." : records.length}
              </span>
            </div>
          </div>
        </div>

        {/* Main Records Table Frame */}
        <div className="bg-zinc-950/40 backdrop-blur-xl border border-white/5 rounded-2xl shadow-2xl relative overflow-hidden">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-24 gap-3">
              <Loader2 className="w-8 h-8 animate-spin text-emerald-400" />
              <p className="font-mono text-xs text-zinc-500 tracking-widest uppercase animate-pulse">
                Querying Telemetry Stream...
              </p>
            </div>
          ) : records.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 gap-2 text-zinc-500">
              <Info size={24} className="text-zinc-600" />
              <p className="font-mono text-xs tracking-wide">
                No health logs returned for this identity vector.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto custom-scrollbar">
              <table className="w-full text-left border-collapse text-xs whitespace-nowrap">
                <thead>
                  <tr className="border-b border-zinc-900 bg-white/[0.01] text-zinc-400 font-mono tracking-wider uppercase text-[10px]">
                    <th className="p-4 font-semibold">Date Logged</th>
                    <th className="p-4 font-semibold">Activity (Steps / Dist)</th>
                    <th className="p-4 font-semibold">Active Time & Floors</th>
                    <th className="p-4 font-semibold">Energy Output</th>
                    <th className="p-4 font-semibold">Heart Dynamics</th>
                    <th className="p-4 font-semibold">Sleep Cycle</th>
                    <th className="p-4 font-semibold">Biometrics (SpO2 / Temp)</th>
                    <th className="p-4 font-semibold">Weight Metric</th>
                    <th className="p-4 font-semibold">Source</th>
                    <th className="p-4 font-semibold text-right">Synced At</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-900/60 font-sans text-zinc-300">
                  {records.map((rec) => (
                    <tr
                      key={rec._id}
                      className="hover:bg-white/[0.01] transition-colors duration-150 group"
                    >
                      {/* Date */}
                      <td className="p-4 font-mono">
                        <div className="flex items-center gap-1.5 font-bold text-zinc-100 group-hover:text-emerald-400 transition-colors">
                          <Calendar size={13} className="text-zinc-500" />
                          <span>{rec.date}</span>
                        </div>
                      </td>

                      {/* Steps & Distance */}
                      <td className="p-4 font-mono">
                        <div className="flex flex-col">
                          <span className="flex items-center gap-1 text-zinc-200">
                            <Footprints size={12} className="text-emerald-400" />
                            {(rec.steps || 0).toLocaleString()} steps
                          </span>
                          <span className="text-[10px] text-zinc-500 mt-0.5">
                            {rec.distanceWalked ? `${rec.distanceWalked} km` : "-"}
                          </span>
                        </div>
                      </td>

                      {/* Active Minutes & Floors */}
                      <td className="p-4 font-mono text-[11px] text-zinc-400">
                        <div className="flex flex-col">
                          <span className="flex items-center gap-1 text-cyan-400">
                            <Zap size={11} />
                            {rec.activeZoneMinutes || 0} active mins
                          </span>
                          <span className="text-[10px] text-zinc-500 mt-0.5">
                            {rec.floors || 0} floors climbed
                          </span>
                        </div>
                      </td>

                      {/* Calories */}
                      <td className="p-4 font-mono text-zinc-300">
                        <div className="flex items-center gap-1">
                          <Flame size={12} className="text-amber-500" />
                          <span>{(rec.calories || 0).toLocaleString()} kcal</span>
                        </div>
                      </td>

                      {/* Heart Rates */}
                      <td className="p-4 font-mono">
                        <div className="flex flex-col text-[11px]">
                          <span className="flex items-center gap-1 text-rose-400">
                            <Heart size={12} />
                            Avg: {rec.heartRate || "-"} bpm
                          </span>
                          <span className="text-[10px] text-zinc-500 mt-0.5">
                            Resting: {rec.restingHeartRate || "-"} bpm
                          </span>
                        </div>
                      </td>

                      {/* Sleep Duration */}
                      <td className="p-4 font-mono">
                        <div className="flex items-center gap-1 text-indigo-300">
                          <Moon size={12} className="text-indigo-400" />
                          <span>{rec.sleepHours ? `${rec.sleepHours} hrs` : "-"}</span>
                        </div>
                      </td>

                      {/* SpO2 & Body Temp */}
                      <td className="p-4 font-mono text-[11px] text-zinc-400">
                        <div className="flex flex-col">
                          <span>SpO2: {rec.bloodOxygen ? `${rec.bloodOxygen}%` : "-"}</span>
                          <span className="text-[10px] text-zinc-500 flex items-center gap-0.5 mt-0.5">
                            <Thermometer size={10} />
                            {rec.bodyTemperature ? `${rec.bodyTemperature} °C` : "-"}
                          </span>
                        </div>
                      </td>

                      {/* Weight */}
                      <td className="p-4 font-mono text-zinc-400">
                        <div className="flex items-center gap-1">
                          <Scale size={12} className="text-zinc-500" />
                          <span>{rec.weight ? `${rec.weight} kg` : "-"}</span>
                        </div>
                      </td>

                      {/* Source */}
                      <td className="p-4 font-mono text-[11px]">
                        <span className="px-2 py-0.5 rounded bg-zinc-900 border border-zinc-800 text-zinc-400 uppercase">
                          {rec.source || "Unknown"}
                        </span>
                      </td>

                      {/* Synced At Timestamp */}
                      <td className="p-4 text-right font-mono text-zinc-500 text-[11px]">
                        {rec.syncedAt
                          ? new Date(rec.syncedAt).toLocaleString([], {
                              dateStyle: "short",
                              timeStyle: "short",
                            })
                          : "-"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </main>

      <style jsx global>{`
        @keyframes fadeIn {
          from {
            opacity: 0;
            transform: translateY(8px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        .custom-scrollbar::-webkit-scrollbar {
          height: 6px;
          width: 6px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: rgba(0, 0, 0, 0.2);
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: rgba(255, 255, 255, 0.05);
          border-radius: 99px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
          background: rgba(16, 185, 129, 0.2);
        }
      `}</style>
    </div>
  );
}