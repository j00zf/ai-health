"use client";

import { useState, useEffect, useRef } from "react";
import { loginAdmin } from "../../services/auth.service";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { Eye, EyeOff, Loader2, AlertCircle, CheckCircle, ShieldAlert } from "lucide-react";

export default function LoginPage() {
  const router = useRouter();
  const emailInputRef = useRef<HTMLInputElement>(null);

  const [form, setForm] = useState({
    email: "",
    password: "",
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [focusedField, setFocusedField] = useState<"email" | "password" | null>(null);

  useEffect(() => {
    emailInputRef.current?.focus();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setSuccess("");
    setLoading(true);

    try {
      const response = await loginAdmin(form);
      localStorage.setItem("token", response.data.token);
      localStorage.setItem("admin", JSON.stringify(response.data.admin));

      setSuccess("Access granted. Initializing session...");
      
      setTimeout(() => {
        router.push("/dashboard");
      }, 1200);
    } catch (err: any) {
      const message =
        err?.response?.data?.message || err?.message || "Invalid credentials. Please try again.";
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: "email" | "password") => (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [field]: e.target.value });
    if (error) setError("");
  };

  return (
    <div className="min-h-screen w-full flex flex-col items-center justify-center relative overflow-hidden bg-[#050505] font-sans selection:bg-emerald-500/30 selection:text-emerald-400 p-4">
      
      {/* --- Ambient Sci-Fi Background --- */}
      <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
        <div 
          className="absolute inset-0 bg-[linear-gradient(to_right,#141414_1px,transparent_1px),linear-gradient(to_bottom,#141414_1px,transparent_1px)] bg-[size:45px_45px]" 
          style={{ maskImage: 'radial-gradient(ellipse at center, black 40%, transparent 80%)', WebkitMaskImage: 'radial-gradient(ellipse at center, black 40%, transparent 80%)' }}
        />
        <div className="absolute top-[25%] w-full h-[1px] bg-gradient-to-r from-transparent via-emerald-500 to-transparent opacity-20 animate-[ping_5s_ease-in-out_infinite]" />
        <div className="absolute top-[70%] w-full h-[1px] bg-gradient-to-r from-transparent via-cyan-500 to-transparent opacity-10 animate-[ping_7s_ease-in-out_infinite] delay-1000" />
      </div>

      {/* --- Main Center Glass Split Card --- */}
      <div className="w-full max-w-4xl z-10 relative transition-all duration-500 animate-[fadeIn_0.6s_ease-out_forwards]">
        
        {/* Dynamic Multi-Color Border Aura */}
        <div className={`absolute -inset-px rounded-3xl transition-all duration-700 blur-[2px] ${
          error 
            ? "bg-gradient-to-r from-red-500/30 via-zinc-800 to-red-500/30" 
            : focusedField === 'email' 
            ? "bg-gradient-to-r from-emerald-500/30 via-zinc-900 to-zinc-900" 
            : focusedField === 'password'
            ? "bg-gradient-to-r from-zinc-900 via-zinc-900 to-cyan-500/30"
            : "bg-white/5"
        }`} />

        {/* Main Content Pane Split Grid */}
        <div className="relative bg-zinc-950/75 backdrop-blur-xl rounded-3xl overflow-hidden shadow-[0_25px_50px_-12px_rgba(0,0,0,0.8)] grid grid-cols-1 md:grid-cols-12 min-h-[480px]">
          
          {/* LEFT COLUMN: Clean Minimalist Logo & System Identity */}
          <div className="md:col-span-5 flex flex-col items-center justify-center p-8 bg-black/20 border-b md:border-b-0 md:border-r border-zinc-900/50 relative overflow-hidden group">
            
            {/* Dynamic Background Radial Glow behind the Borderless Logo */}
            <div className={`absolute w-48 h-48 rounded-full blur-[80px] transition-all duration-700 -z-10 ${
              focusedField === 'email' 
                ? 'bg-emerald-500/10' 
                : focusedField === 'password' 
                ? 'bg-cyan-500/10' 
                : 'bg-emerald-500/5'
            }`} />

            <div className="relative w-24 h-24 mb-5 transition-transform duration-500 group-hover:scale-105">
              <Image
                src="/favicon.png"
                alt="Pulse AI Logo"
                fill
                className="object-contain filter drop-shadow-[0_0_15px_rgba(16,185,129,0.5)]"
                priority
              />
            </div>
            
            <h1 className="text-2xl font-black tracking-tight text-white mb-1.5 bg-gradient-to-b from-white to-zinc-400 bg-clip-text text-transparent">
              Pulse AI
            </h1>
            
            <div className="flex items-center gap-2">
              <span className={`w-1.5 h-1.5 rounded-full animate-pulse ${error ? 'bg-red-500' : 'bg-emerald-500'}`} />
              <p className="text-zinc-500 text-[10px] font-mono tracking-[4px] uppercase">
                {error ? 'System Alert' : 'Terminal Gateway'}
              </p>
            </div>
          </div>

          {/* RIGHT COLUMN: Interactive Login Credentials */}
          <div className="md:col-span-7 flex flex-col justify-center p-8 sm:p-10 lg:p-12">
            <div className="mb-6">
              <h2 className="text-lg font-medium text-zinc-100 tracking-tight">Security Verification</h2>
              <p className="text-zinc-500 text-xs mt-1">Authorized grid operators only</p>
            </div>

            {/* Banners */}
            {error && (
              <div className="mb-5 flex items-start gap-3 rounded-xl bg-red-950/20 border border-red-500/20 p-3.5 text-red-400 text-xs animate-[shake_0.4s_ease-in-out]">
                <AlertCircle className="w-4 h-4 flex-shrink-0 text-red-500 mt-0.5" />
                <div className="space-y-0.5">
                  <p className="font-semibold uppercase tracking-wider text-[9px]">Terminal Error</p>
                  <p className="text-zinc-300">{error}</p>
                </div>
              </div>
            )}

            {success && (
              <div className="mb-5 flex items-start gap-3 rounded-xl bg-emerald-950/20 border border-emerald-500/20 p-3.5 text-emerald-400 text-xs">
                <CheckCircle className="w-4 h-4 flex-shrink-0 text-emerald-400 mt-0.5" />
                <div className="space-y-0.5">
                  <p className="font-semibold uppercase tracking-wider text-[9px]">Access Granted</p>
                  <p className="text-zinc-300">{success}</p>
                </div>
              </div>
            )}

            {/* Input fields form */}
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <label htmlFor="email" className="block text-[10px] font-bold tracking-widest text-zinc-500 uppercase ml-0.5">
                  Identity Profile (Email)
                </label>
                <input
                  ref={emailInputRef}
                  id="email"
                  type="email"
                  placeholder="name@pulse-ai.io"
                  className="w-full px-4 py-3 bg-white/[0.01] border border-zinc-850 rounded-xl focus:border-emerald-500/70 focus:ring-1 focus:ring-emerald-500/20 transition-all duration-300 text-white placeholder-zinc-600 outline-none text-sm font-mono"
                  value={form.email}
                  onChange={handleInputChange("email")}
                  onFocus={() => setFocusedField("email")}
                  onBlur={() => setFocusedField(null)}
                  required
                />
              </div>

              <div className="space-y-1.5">
                <label htmlFor="password" className="block text-[10px] font-bold tracking-widest text-zinc-500 uppercase ml-0.5">
                  Security Pass
                </label>
                <div className="relative">
                  <input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    placeholder="••••••••"
                    className="w-full px-4 py-3 bg-white/[0.01] border border-zinc-850 rounded-xl focus:border-cyan-500/70 focus:ring-1 focus:ring-cyan-500/20 transition-all duration-300 text-white placeholder-zinc-600 outline-none text-sm font-mono pr-11"
                    value={form.password}
                    onChange={handleInputChange("password")}
                    onFocus={() => setFocusedField("password")}
                    onBlur={() => setFocusedField(null)}
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-zinc-500 hover:text-cyan-400 transition-colors p-1"
                    aria-label={showPassword ? "Hide password" : "Show password"}
                  >
                    {showPassword ? <EyeOff size={15} /> : <Eye size={15} />}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full mt-3 py-3.5 bg-emerald-300 text-black font-bold rounded-xl text-xs tracking-widest uppercase transition-all duration-300 active:scale-[0.985] disabled:bg-zinc-900 disabled:text-zinc-600 border Login hover:bg-transparent hover:text-white hover:border-emerald-500 shadow-[0_0_15px_rgba(255,255,255,0.02)] hover:shadow-[0_0_20px_rgba(16,185,129,0.15)] flex items-center justify-center gap-2"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-3.5 h-3.5 animate-spin text-emerald-400" />
                    <span className="font-mono text-[10px] text-emerald-400">Authenticating...</span>
                  </>
                ) : (
                  "Login"
                )}
              </button>
            </form>

           
          </div>

        </div>
      </div>

      {/* --- Micro Console Status Footer --- */}
      <div className="absolute bottom-6 text-center text-[9px] text-zinc-600 font-mono tracking-[0.25em] z-10 pointer-events-none uppercase">
        System Status: Secure • Protocol V4.2
      </div>

      <style jsx global>{`
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-4px); }
          75% { transform: translateX(4px); }
        }
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(12px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}