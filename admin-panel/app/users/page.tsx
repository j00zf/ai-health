"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { getUsers } from "@/services/user.service";
import Sidebar from "@/components/Sidebar";
import {
  Users,
  Loader2,
  Info,
  RefreshCw,
  Calendar,
  ArrowUpRight,
  Activity,
} from "lucide-react";

export default function UsersPage() {
  const router = useRouter();
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) {
      router.push("/login");
      return;
    }
    fetchUsers();
  }, [router]);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const data = await getUsers();
      setUsers(data.users || []);
    } catch (error) {
      console.error("Error fetching user array:", error);
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
      {/* --- Ambient Immersive Background Node Matrix --- */}
      <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
        <div
          className="absolute inset-0 bg-[linear-gradient(to_right,#141414_1px,transparent_1px),linear-gradient(to_bottom,#141414_1px,transparent_1px)] bg-[size:45px_45px]"
          style={{
            maskImage:
              "radial-gradient(ellipse at center, black 30%, transparent 80%)",
            WebkitMaskImage:
              "radial-gradient(ellipse at center, black 30%, transparent 80%)",
          }}
        />
        <div className="absolute top-[10%] left-[40%] w-[500px] h-[500px] bg-emerald-500/[0.02] rounded-full blur-[140px] animate-pulse" />
      </div>

      {/* Shared Sidebar Component Workspace */}
      <Sidebar onLogout={logout} />

      {/* --- Main Contents Stack Container --- */}
      <main className="flex-1 p-8 lg:p-10 z-10 overflow-y-auto w-full space-y-6 animate-[fadeIn_0.5s_ease-out_forwards]">
        {/* Header Control Hub Row */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-zinc-900 pb-5">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <Users size={14} className="text-emerald-400" />
              <span className="text-[10px] font-mono tracking-[0.3em] text-zinc-500 uppercase">
                Core Registries
              </span>
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-white bg-gradient-to-b from-white to-zinc-400 bg-clip-text text-transparent">
              User Management
            </h1>
          </div>

          <div className="flex items-center gap-3 self-end sm:self-auto">
            <button 
              onClick={fetchUsers}
              disabled={loading}
              className="p-2.5 bg-zinc-900  hover:bg-slate-600  rounded-xl transition-colors disabled:opacity-40"
              title="Refresh Registry"
            >
              <RefreshCw
                size={14}
                className={`${
                  loading ? "animate-spin text-emerald-400" : "text-zinc-400"
                }`}
              />
            </button>
            <div className="bg-zinc-950/40 border border-zinc-850 px-4 py-2 rounded-xl font-mono text-xs text-zinc-400 tracking-wider">
              TOTAL RECORD NODES:{" "}
              <span className="text-emerald-400 font-bold ml-1">
                {loading ? "..." : users.length}
              </span>
            </div>
          </div>
        </div>

        {/* --- Main Table Frame --- */}
        <div className="bg-zinc-950/40 backdrop-blur-xl border border-white/5 rounded-2xl shadow-2xl relative overflow-hidden">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-24 gap-3">
              <Loader2 className="w-8 h-8 animate-spin text-emerald-400" />
              <p className="font-mono text-xs text-zinc-500 tracking-widest uppercase animate-pulse">
                Querying Database Grid...
              </p>
            </div>
          ) : users.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 gap-2 text-zinc-500">
              <Info size={24} className="text-zinc-600" />
              <p className="font-mono text-xs tracking-wide">
                No identity data structures returned from remote vector.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto custom-scrollbar">
              <table className="w-full text-left border-collapse text-xs whitespace-nowrap">
                <thead>
                  <tr className="border-b border-zinc-900 bg-white/[0.01] text-zinc-400 font-mono tracking-wider uppercase text-[10px]">
                    <th className="p-4 font-semibold">Account Identity</th>
                    <th className="p-4 font-semibold text-center">Telemetry</th>
                    <th className="p-4 font-semibold">Provider</th>
                    <th className="p-4 font-semibold">Profile Status</th>
                    <th className="p-4 font-semibold">Last Contact</th>
                    <th className="p-4 font-semibold">Codename</th>
                    <th className="p-4 font-semibold text-center">Age</th>
                    <th className="p-4 font-semibold">Sex</th>
                    <th className="p-4 font-semibold text-right">
                      Metrics (H / W)
                    </th>
                    <th className="p-4 font-semibold text-center">BMI</th>
                    <th className="p-4 font-semibold">Activity Baseline</th>
                    <th className="p-4 font-semibold">Primary Directive</th>
                    <th className="p-4 font-semibold">Fitbit Link</th>
                    <th className="p-4 font-semibold text-right">
                      Provision Date
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-900/60 font-sans text-zinc-300">
                  {users.map((user) => (
                    <tr
                      key={user._id}
                      className="hover:bg-white/[0.01] transition-colors duration-150 group"
                    >
                      {/* Name & Email Identity Group */}
                      <td className="p-4">
                        <div className="flex flex-col">
                          <span className="font-semibold text-zinc-100 group-hover:text-emerald-400 transition-colors text-sm">
                            {user.name}
                          </span>
                          <span className="text-[11px] text-zinc-500 font-mono tracking-tight mt-0.5">
                            {user.email}
                          </span>
                          {user.phone && (
                            <span className="text-[10px] text-zinc-600 font-mono mt-0.5">
                              {user.phone}
                            </span>
                          )}
                        </div>
                      </td>

                      {/* Action Button: Jump to Health Logs */}
                      <td className="p-4 text-center">
                        <button
                          onClick={() =>
                            router.push(`/users/${user._id}/records`)
                          }
                          className="inline-flex items-center gap-1 text-[11px] font-mono text-emerald-400 hover:text-emerald-300 bg-emerald-500/10 hover:bg-emerald-500/20 px-2.5 py-1.5 rounded-lg border border-emerald-500/20 transition-all active:scale-95"
                          title="View telemetry health logs"
                        >
                          <Activity size={12} />
                          <span>Logs</span>
                          <ArrowUpRight size={12} />
                        </button>
                      </td>

                      {/* Provider badge */}
                      <td className="p-4 font-mono text-[11px]">
                        <span className="px-2 py-0.5 rounded bg-zinc-900 border border-zinc-800 text-zinc-400 capitalize">
                          {user.authProvider || "Local"}
                        </span>
                      </td>

                      {/* Profile Status Check */}
                      <td className="p-4">
                        {user.profileCompleted ? (
                          <span className="inline-flex items-center gap-1 text-[11px] font-medium text-emerald-400 bg-emerald-500/5 px-2.5 py-1 rounded-lg border border-emerald-500/10">
                            <span className="w-1 h-1 rounded-full bg-emerald-400" />{" "}
                            Completed
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] font-medium text-amber-500 bg-amber-500/5 px-2.5 py-1 rounded-lg border border-amber-500/10">
                            <span className="w-1 h-1 rounded-full bg-amber-500" />{" "}
                            Incomplete
                          </span>
                        )}
                      </td>

                      {/* Last Login Parsing */}
                      <td className="p-4 font-mono text-zinc-400 text-[11px]">
                        {user.lastLogin ? (
                          <span className="opacity-80">
                            {new Date(user.lastLogin).toLocaleString([], {
                              dateStyle: "short",
                              timeStyle: "short",
                            })}
                          </span>
                        ) : (
                          <span className="text-zinc-600">-</span>
                        )}
                      </td>

                      {/* Nickname string */}
                      <td className="p-4 font-medium text-zinc-300">
                        {user.profile?.nickname || (
                          <span className="text-zinc-600">-</span>
                        )}
                      </td>

                      {/* Age */}
                      <td className="p-4 text-center font-mono">
                        {user.profile?.age || (
                          <span className="text-zinc-600">-</span>
                        )}
                      </td>

                      {/* Gender string formatting badge */}
                      <td className="p-4 font-mono text-[11px] text-zinc-400 capitalize">
                        {user.profile?.gender || (
                          <span className="text-zinc-600">-</span>
                        )}
                      </td>

                      {/* Height / Weight Combined Metric Node */}
                      <td className="p-4 text-right font-mono text-zinc-400">
                        {user.profile?.height || user.profile?.weight ? (
                          <div className="flex flex-col text-[11px]">
                            <span>
                              {user.profile.height
                                ? `${user.profile.height} cm`
                                : "-"}
                            </span>
                            <span className="text-zinc-600 text-[10px] mt-0.5">
                              {user.profile.weight
                                ? `${user.profile.weight} kg`
                                : "-"}
                            </span>
                          </div>
                        ) : (
                          <span className="text-zinc-600">-</span>
                        )}
                      </td>

                      {/* Calculated BMI index */}
                      <td className="p-4 text-center font-mono font-bold text-zinc-200">
                        {user.profile?.bmi || (
                          <span className="text-zinc-600">-</span>
                        )}
                      </td>

                      {/* Activity string level text block */}
                      <td className="p-4 text-zinc-400 text-[11px]">
                        {user.profile?.activityLevel ? (
                          <span
                            className="max-w-[120px] truncate block"
                            title={user.profile.activityLevel}
                          >
                            {user.profile.activityLevel}
                          </span>
                        ) : (
                          <span className="text-zinc-600">-</span>
                        )}
                      </td>

                      {/* Health goal target string profile element */}
                      <td className="p-4 text-zinc-400 text-[11px]">
                        {user.profile?.healthGoal ? (
                          <span
                            className="max-w-[140px] truncate block"
                            title={user.profile.healthGoal}
                          >
                            {user.profile.healthGoal}
                          </span>
                        ) : (
                          <span className="text-zinc-600">-</span>
                        )}
                      </td>

                      {/* Fitbit Core Connected Matrix Flag */}
                      <td className="p-4">
                        {user.profile?.fitbitConnected ? (
                          <span className="text-[10px] uppercase font-bold font-mono tracking-wider px-2 py-0.5 bg-cyan-950/30 border border-cyan-500/20 text-cyan-400 rounded">
                            Connected
                          </span>
                        ) : (
                          <span className="text-[10px] uppercase font-mono tracking-wider px-2 py-0.5 bg-zinc-900 text-zinc-600 border border-transparent rounded">
                            Offline
                          </span>
                        )}
                      </td>

                      {/* Created Node Timestamp */}
                      <td className="p-4 text-right font-mono text-zinc-500 text-[11px]">
                        <div className="flex items-center justify-end gap-1.5">
                          <Calendar size={11} className="opacity-40" />
                          <span>
                            {new Date(user.createdAt).toLocaleDateString([], {
                              year: "numeric",
                              month: "short",
                              day: "2-digit",
                            })}
                          </span>
                        </div>
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