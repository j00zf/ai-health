"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import api from "@/services/api";
import Sidebar from "@/components/Sidebar"; // Adjust path as necessary
import { Users, Shield, CheckCircle2, Activity, ShieldCheck, ExternalLink } from "lucide-react";

export default function DashboardPage() {
  const router = useRouter();

  const [admin, setAdmin] = useState<any>(null);
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalAdmins: 0,
    completedProfiles: 0,
    fitbitConnected: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem("token");

    if (!token) {
      router.push("/login");
      return;
    }

    const adminData = localStorage.getItem("admin");
    if (adminData) {
      setAdmin(JSON.parse(adminData));
    }

    loadDashboard();
  }, [router]);

  const loadDashboard = async () => {
    try {
      const response = await api.get("/admin/dashboard/stats");
      setStats(response.data.stats);
    } catch (error) {
      console.error("Dashboard Error:", error);
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
          style={{ maskImage: 'radial-gradient(ellipse at center, black 30%, transparent 80%)', WebkitMaskImage: 'radial-gradient(ellipse at center, black 30%, transparent 80%)' }}
        />
        <div className="absolute top-[20%] right-10 w-[500px] h-[500px] bg-emerald-500/[0.03] rounded-full blur-[130px] animate-pulse" />
        <div className="absolute bottom-[10%] left-1/3 w-[600px] h-[600px] bg-cyan-500/[0.02] rounded-full blur-[150px] animate-pulse delay-1000" />
      </div>

      {/* Modular Shared Sidebar Workspace */}
      <Sidebar onLogout={logout} />

      {/* --- Main Workspace Workspace --- */}
      <main className="flex-1 p-8 lg:p-10 z-10 overflow-y-auto max-w-[1600px] mx-auto w-full space-y-8 animate-[fadeIn_0.5s_ease-out_forwards]">
        
        {/* Welcome Banner Card Header */}
        <div className="relative group overflow-hidden rounded-3xl border border-white/5 bg-zinc-950/40 backdrop-blur-xl p-8 shadow-[0_20px_40px_-15px_rgba(0,0,0,0.7)]">
          <div className="absolute -inset-px bg-gradient-to-r from-emerald-500/10 via-transparent to-transparent opacity-40 group-hover:opacity-70 transition duration-700" />
          <div className="relative flex flex-col md:flex-row md:items-center justify-between gap-6">
            <div>
              <div className="flex items-center gap-2 mb-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
                <span className="text-[10px] font-mono tracking-[0.3em] text-emerald-400 uppercase">Operational Session</span>
              </div>
              <h2 className="text-3xl font-bold tracking-tight text-white bg-gradient-to-b from-white to-zinc-400 bg-clip-text text-transparent">
                Welcome, {admin?.name || "System Operator"}
              </h2>
              <p className="text-zinc-500 text-sm mt-1 font-mono">{admin?.email}</p>
            </div>
            
            {/* Operator System Badge */}
            <div className="flex items-center gap-3 px-4 py-2.5 bg-white/[0.02] border border-zinc-850 rounded-xl max-w-fit">
              <ShieldCheck size={18} className="text-emerald-400" />
              <div className="font-mono text-left">
                <p className="text-[9px] text-zinc-500 uppercase tracking-wider leading-none">Security Clearance</p>
                <p className="text-xs font-bold text-zinc-300 uppercase mt-1">{admin?.status || "active"}</p>
              </div>
            </div>
          </div>
        </div>

        {/* --- Analytical Telemetry Grid --- */}
        <div>
          <h3 className="text-xs font-bold font-mono tracking-[0.2em] text-zinc-500 uppercase mb-4 ml-1">System Metrics</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            {[
              { label: "Total Users", value: stats.totalUsers, icon: Users, color: "from-emerald-500/20" },
              { label: "Total Admins", value: stats.totalAdmins, icon: Shield, color: "from-cyan-500/20" },
              { label: "Profiles Completed", value: stats.completedProfiles, icon: CheckCircle2, color: "from-purple-500/20" },
              { label: "Fitbit Connected", value: stats.fitbitConnected, icon: Activity, color: "from-orange-500/20" },
            ].map((stat, idx) => (
              <div key={idx} className="relative group overflow-hidden bg-zinc-950/40 backdrop-blur-xl border border-white/5 rounded-2xl p-6 shadow-xl transition-all duration-300 hover:border-zinc-800">
                <div className={`absolute -inset-px bg-gradient-to-br ${stat.color} to-transparent opacity-0 group-hover:opacity-20 transition duration-500 rounded-2xl`} />
                <div className="flex items-center justify-between">
                  <span className="text-xs font-mono tracking-wider text-zinc-500 uppercase">{stat.label}</span>
                  <stat.icon size={16} className="text-zinc-600 group-hover:text-zinc-400 transition-colors" />
                </div>
                <p className="text-4xl font-extrabold tracking-tight mt-4 font-mono">
                  {loading ? (
                    <span className="inline-block w-8 h-8 bg-zinc-800 animate-pulse rounded" />
                  ) : (
                    stat.value
                  )}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* --- System Terminal Actions Pipeline --- */}
        <div>
          <h3 className="text-xs font-bold font-mono tracking-[0.2em] text-zinc-500 uppercase mb-4 ml-1">Execution Gates</h3>
          <div className="bg-zinc-950/40 backdrop-blur-xl border border-white/5 rounded-3xl p-6 sm:p-8 shadow-2xl relative">
            <div className="absolute inset-x-0 top-0 h-[1px] bg-gradient-to-r from-transparent via-zinc-800 to-transparent" />
            
            <div className="mb-6">
              <h4 className="text-md font-medium text-zinc-200 tracking-tight">Quick Actions Matrix</h4>
              <p className="text-xs text-zinc-500 mt-1">Direct pipeline controls for rapid administration routing.</p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              {[
                { name: "View Users", route: "/users", style: "border-emerald-500/30 text-emerald-400 hover:bg-emerald-500/5 shadow-[0_0_15px_rgba(16,185,129,0.02)]" },
                { name: "View Admins", route: "/admins", style: "border-cyan-500/30 text-cyan-400 hover:bg-cyan-500/5 shadow-[0_0_15px_rgba(6,182,212,0.02)]" },
                { name: "Admin Profile", route: "/admin/profile", style: "border-zinc-800 text-zinc-300 hover:bg-white/[0.02]" },
              ].map((btn, index) => (
                <button
                  key={index}
                  onClick={() => router.push(btn.route)}
                  className={`group relative flex items-center justify-between px-5 py-4 border rounded-xl font-mono text-xs tracking-widest uppercase transition-all duration-300 active:scale-[0.985] ${btn.style}`}
                >
                  <span>{btn.name}</span>
                  <ExternalLink size={13} className="opacity-40 group-hover:opacity-100 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all" />
                </button>
              ))}
            </div>
          </div>
        </div>

      </main>

      <style jsx global>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}