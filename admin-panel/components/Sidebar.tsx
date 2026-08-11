"use client";

import { usePathname, useRouter } from "next/navigation";
import Image from "next/image";
import { LayoutDashboard, Users, ShieldAlert, UserCog, LogOut,Activity } from "lucide-react";

interface SidebarProps {
  onLogout: () => void;
}

export default function Sidebar({ onLogout }: SidebarProps) {
  const router = useRouter();
  const pathname = usePathname();

  const navigation = [
    { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
    { name: "View Users", href: "/users", icon: Users },
    { name: "View Admins", href: "/admin", icon: ShieldAlert },
    { name: "Admin Profile", href: "/admin/profile", icon: UserCog },
    { name : "Health Dataset", href: "/health", icon: Activity },
  ];

  return (
    <aside className="w-68 min-h-screen bg-zinc-950/40 backdrop-blur-xl border-r border-zinc-900 flex flex-col justify-between p-6 z-20 shrink-0">
      <div className="space-y-8">
        {/* Borderless Identity Header */}
        <div className="flex items-center gap-3 pl-2">
          <div className="relative w-8 h-8 shrink-0">
            <Image
              src="/favicon.png"
              alt="Pulse AI Logo"
              fill
              className="object-contain filter drop-shadow-[0_0_8px_rgba(16,185,129,0.5)]"
              priority
            />
          </div>
          <div>
            <h1 className="text-md font-black text-white tracking-tight leading-none">Pulse AI</h1>
            <span className="text-[9px] font-mono tracking-widest text-emerald-400 uppercase">Console v4.2</span>
          </div>
        </div>

        {/* Dynamic Navigation Stack */}
        <nav className="space-y-1.5">
          {navigation.map((item) => {
            const isActive = pathname === item.href;
            return (
              <button
                key={item.name}
                onClick={() => router.push(item.href)}
                className={`w-full flex 1 text-zinc-200 items-center gap-3 px-4 py-3 rounded-xl font-mono text-xs tracking-wider uppercase transition-all duration-200 group ${
                  isActive
                    ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 shadow-[0_0_15px_rgba(16,185,129,0.05)]"
                    : "text-zinc-500 hover:text-zinc-200 hover:bg-white/[0.02] border border-transparent"
                }`}
              >
                <item.icon 
                  size={16} 
                  className={`transition-colors duration-200 ${
                    isActive ? "text-emerald-400" : "text-zinc-500 group-hover:text-zinc-300"
                  }`} 
                />
                {item.name}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Action Terminate Footer */}
      <button
        onClick={onLogout}
        className="w-full flex items-center gap-3 px-4 py-3 rounded-xl font-mono text-xs tracking-wider uppercase text-zinc-500 hover:text-red-400 hover:bg-red-950/20 border border-transparent hover:border-red-500/20 transition-all duration-300 group"
      >
        <LogOut size={16} className="text-zinc-500 group-hover:text-red-400 transition-colors" />
        Disconnect
      </button>
    </aside>
  );
}