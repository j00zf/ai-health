"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import api from "@/services/api";
import Sidebar from "@/components/Sidebar"; // Adjust path as necessary
import { ShieldAlert, Loader2, RefreshCw, Calendar, Terminal, ShieldCheck } from "lucide-react";

export default function AdminsPage() {
  const router = useRouter();
  const [admins, setAdmins] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) {
      router.push("/login");
      return;
    }
    fetchAdmins();
  }, [router]);

  const fetchAdmins = async () => {
    setLoading(true);
    try {
      const res = await api.get("/admins/all");
      setAdmins(res.data.admins || []);
    } catch (error) {
      console.error("Error query mapping core operators:", error);
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
    <div className="min-h-screen w-full bg-[#050505] flex text-white font-sans relative overflow-hidden selection:bg-cyan-500/30 selection:text-cyan-400">
      
      {/* --- Ambient Immersive Background Node Matrix --- */}
      <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
        <div 
          className="absolute inset-0 bg-[linear-gradient(to_right,#141414_1px,transparent_1px),linear-gradient(to_bottom,#141414_1px,transparent_1px)] bg-[size:45px_45px]" 
          style={{ maskImage: 'radial-gradient(ellipse at center, black 30%, transparent 80%)', WebkitMaskImage: 'radial-gradient(ellipse at center, black 30%, transparent 80%)' }}
        />
        <div className="absolute bottom-[20%] right-[30%] w-[500px] h-[500px] bg-cyan-500/[0.02] rounded-full blur-[140px] animate-pulse" />
      </div>

      {/* Shared Sidebar Component Workspace */}
      <Sidebar onLogout={logout} />

      {/* --- Main Contents Stack Container --- */}
      <main className="flex-1 p-8 lg:p-10 z-10 overflow-y-auto w-full space-y-6 animate-[fadeIn_0.5s_ease-out_forwards]">
        
        {/* Header Control Hub Row */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-zinc-900 pb-5">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <ShieldAlert size={14} className="text-cyan-400" />
              <span className="text-[10px] font-mono tracking-[0.3em] text-zinc-500 uppercase">Root Matrix Authority</span>
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-white bg-gradient-to-b from-white to-zinc-400 bg-clip-text text-transparent">
              Admin Management
            </h1>
          </div>

          <div className="flex items-center gap-3 self-end sm:self-auto">
            <button 
              onClick={fetchAdmins}
              disabled={loading}
              className="p-2.5 bg-zinc-900  hover:bg-slate-600  rounded-xl transition-colors disabled:opacity-40"
              title="Refresh Registry"
            >
              <RefreshCw size={14} className={`${loading ? 'animate-spin text-cyan-400' : 'text-zinc-400'}`} />
            </button>
            <div className="bg-zinc-950/40 border border-zinc-850 px-4 py-2 rounded-xl font-mono text-xs text-zinc-400 tracking-wider">
              TOTAL OPERATORS: <span className="text-cyan-400 font-bold ml-1">{loading ? "..." : admins.length}</span>
            </div>
          </div>
        </div>

        {/* --- Main Table Frame --- */}
        <div className="bg-zinc-950/40 backdrop-blur-xl border border-white/5 rounded-2xl shadow-2xl relative overflow-hidden">
          
          {loading ? (
            <div className="flex flex-col items-center justify-center py-24 gap-3">
              <Loader2 className="w-8 h-8 animate-spin text-cyan-400" />
              <p className="font-mono text-xs text-zinc-500 tracking-widest uppercase animate-pulse">Scanning Grid Privileges...</p>
            </div>
          ) : admins.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 gap-2 text-zinc-500">
              <Terminal size={24} className="text-zinc-600" />
              <p className="font-mono text-xs tracking-wide">No administrative units registered in remote database.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs whitespace-nowrap">
                <thead>
                  <tr className="border-b border-zinc-900 bg-white/[0.01] text-zinc-400 font-mono tracking-wider uppercase text-[10px]">
                    <th className="p-4 font-semibold">Operator Signature</th>
                    <th className="p-4 font-semibold">Identity Endpoint (Email)</th>
                    <th className="p-4 font-semibold">Security Clearance Status</th>
                    <th className="p-4 font-semibold">Last Node Verification</th>
                    <th className="p-4 font-semibold text-right">Commissioned Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-900/60 font-sans text-zinc-300">
                  {admins.map((admin: any) => (
                    <tr 
                      key={admin._id} 
                      className="hover:bg-white/[0.01] transition-colors duration-150 group"
                    >
                      {/* Name Cell */}
                      <td className="p-4">
                        <div className="flex items-center gap-2">
                          <div className="p-1 rounded bg-cyan-500/5 text-cyan-400/70 border border-cyan-500/10">
                            <ShieldCheck size={12} />
                          </div>
                          <span className="font-semibold text-zinc-100 group-hover:text-cyan-400 transition-colors text-sm">
                            {admin.name}
                          </span>
                        </div>
                      </td>

                      {/* Email Identity Cell */}
                      <td className="p-4 font-mono text-[11px] text-zinc-400">
                        {admin.email}
                      </td>

                      {/* Status Badging Row */}
                      <td className="p-4">
                        {admin.status === "active" || !admin.status ? (
                          <span className="inline-flex items-center gap-1 text-[11px] font-medium text-cyan-400 bg-cyan-500/5 px-2.5 py-1 rounded-lg border border-cyan-500/10 uppercase tracking-wide font-mono text-[10px]">
                            <span className="w-1 h-1 rounded-full bg-cyan-400 animate-pulse" /> Clear
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] font-medium text-red-500 bg-red-500/5 px-2.5 py-1 rounded-lg border border-red-500/10 uppercase tracking-wide font-mono text-[10px]">
                            <span className="w-1 h-1 rounded-full bg-red-500" /> Revoked
                          </span>
                        )}
                      </td>

                      {/* Last Login Parsing Terminal */}
                      <td className="p-4 font-mono text-zinc-400 text-[11px]">
                        {admin.lastLogin ? (
                          <span className="opacity-80">
                            {new Date(admin.lastLogin).toLocaleString([], { dateStyle: 'short', timeStyle: 'short' })}
                          </span>
                        ) : (
                          <span className="text-zinc-600 font-mono text-xs">--:--</span>
                        )}
                      </td>

                      {/* Created Node Timestamp */}
                      <td className="p-4 text-right font-mono text-zinc-500 text-[11px]">
                        <div className="flex items-center justify-end gap-1.5">
                          <Calendar size={11} className="opacity-40" />
                          <span>{new Date(admin.createdAt).toLocaleDateString([], { year: 'numeric', month: 'short', day: '2-digit' })}</span>
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

      {/* Global custom layout layout transition injection */}
      <style jsx global>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}