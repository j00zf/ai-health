"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Sidebar from "@/components/Sidebar"; // Adjust path as necessary
import { UserCog, ShieldCheck, Mail, Fingerprint, Calendar, ShieldAlert } from "lucide-react";

export default function AdminProfile() {
  const router = useRouter();
  const [admin, setAdmin] = useState<any>(null);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) {
      router.push("/login");
      return;
    }

    const data = localStorage.getItem("admin");
    if (data) {
      setAdmin(JSON.parse(data));
    }
  }, [router]);

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
        <div className="absolute top-[30%] right-[20%] w-[450px] h-[450px] bg-emerald-500/[0.02] rounded-full blur-[130px] animate-pulse" />
      </div>

      {/* Shared Sidebar Component Workspace */}
      <Sidebar onLogout={logout} />

      {/* --- Main Contents Stack Container --- */}
      <main className="flex-1 p-8 lg:p-10 z-10 overflow-y-auto w-full space-y-6 animate-[fadeIn_0.5s_ease-out_forwards]">
        
        {/* Header Control Hub Row */}
        <div className="border-b border-zinc-900 pb-5">
          <div className="flex items-center gap-2 mb-1">
            <UserCog size={14} className="text-emerald-400" />
            <span className="text-[10px] font-mono tracking-[0.3em] text-zinc-500 uppercase">Local Operator Profile</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white bg-gradient-to-b from-white to-zinc-400 bg-clip-text text-transparent">
            Admin Profile Settings
          </h1>
        </div>

        {/* --- Main Profile Data Node Card --- */}
        <div className="max-w-2xl bg-zinc-950/40 backdrop-blur-xl border border-white/5 rounded-3xl shadow-2xl relative overflow-hidden p-6 sm:p-8">
          <div className="absolute top-0 inset-x-0 h-[1px] bg-gradient-to-r from-transparent via-zinc-800 to-transparent" />
          
          {/* Identity Vector Meta Overview */}
          <div className="flex items-start gap-5 border-b border-zinc-900/60 pb-6 mb-6">
            <div className="p-4 bg-emerald-500/5 text-emerald-400 border border-emerald-500/10 rounded-2xl relative">
              <Fingerprint size={32} className="opacity-80" />
              <div className="absolute bottom-1 right-1 w-2.5 h-2.5 bg-emerald-500 rounded-full border-2 border-zinc-950 animate-pulse" />
            </div>
            <div className="space-y-1">
              <h2 className="text-xl font-bold tracking-tight text-zinc-100">{admin?.name || "System Operator"}</h2>
              <div className="flex items-center gap-2">
                <span className="text-[10px] uppercase font-mono tracking-wider px-2 py-0.5 bg-zinc-900 border border-zinc-800 text-zinc-500 rounded">
                  UID: {admin?._id?.slice(-8) || "--------"}
                </span>
                {admin?.status === "active" || !admin?.status ? (
                  <span className="text-[10px] uppercase font-mono tracking-wider px-2 py-0.5 bg-emerald-950/30 border border-emerald-500/20 text-emerald-400 rounded">
                    Operational Status: Secure
                  </span>
                ) : (
                  <span className="text-[10px] uppercase font-mono tracking-wider px-2 py-0.5 bg-red-950/30 border border-red-500/20 text-red-400 rounded">
                    Status: Revoked
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Configuration Parameters Stack */}
          <div className="space-y-4 font-mono text-xs">
            
            {/* Name Attribute Frame */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 bg-white/[0.01] border border-zinc-900 rounded-xl gap-2">
              <span className="text-zinc-500 uppercase tracking-wider flex items-center gap-2">
                <Fingerprint size={14} className="opacity-60 text-zinc-400" /> Operator Signature
              </span>
              <span className="font-sans text-sm font-semibold text-zinc-200">{admin?.name || "-"}</span>
            </div>

            {/* Email Attribute Frame */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 bg-white/[0.01] border border-zinc-900 rounded-xl gap-2">
              <span className="text-zinc-500 uppercase tracking-wider flex items-center gap-2">
                <Mail size={14} className="opacity-60 text-zinc-400" /> Identity Profile Endpoint
              </span>
              <span className="text-zinc-300 select-all">{admin?.email || "-"}</span>
            </div>

            {/* Clearance Level Frame */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 bg-white/[0.01] border border-zinc-900 rounded-xl gap-2">
              <span className="text-zinc-500 uppercase tracking-wider flex items-center gap-2">
                <ShieldCheck size={14} className="opacity-60 text-zinc-400" /> Grid Status Clearance
              </span>
              <span className="text-emerald-400 uppercase tracking-widest font-bold">{admin?.status || "active"}</span>
            </div>

            {/* Timestamp Login Frame */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 bg-white/[0.01] border border-zinc-900 rounded-xl gap-2">
              <span className="text-zinc-500 uppercase tracking-wider flex items-center gap-2">
                <Calendar size={14} className="opacity-60 text-zinc-400" /> Last Session Initialization
              </span>
              <span className="text-zinc-400">
                {admin?.lastLogin ? (
                  new Date(admin.lastLogin).toLocaleString([], { dateStyle: 'long', timeStyle: 'medium' })
                ) : (
                  <span className="text-zinc-600">-</span>
                )}
              </span>
            </div>

          </div>

          {/* Micro Security Advisory Notice Footer */}
          <div className="mt-6 pt-5 border-t border-zinc-900/60 flex items-center gap-2.5 text-[10px] text-zinc-600 font-mono tracking-wide">
            <ShieldAlert size={12} className="opacity-60 text-amber-500/60" />
            <span>Passkey configurations are cryptographic hashes secured across decentralized network relays. Contact root cluster architecture to adjust signature properties.</span>
          </div>

        </div>
      </main>

      {/* Global page interaction transition layout context injection hook */}
      <style jsx global>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}