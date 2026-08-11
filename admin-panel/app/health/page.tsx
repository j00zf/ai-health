"use client";

import React, { useEffect, useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import { getAllHealthRecords } from "@/services/health.service";
import Sidebar from "@/components/Sidebar";
import {
  Activity,
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
  Search,
  Download,
  Database,
  FileSpreadsheet,
  Clock,
} from "lucide-react";

export default function GlobalHealthRecordsPage() {
  const router = useRouter();
  const [records, setRecords] = useState<any[]>([]);
  const [summary, setSummary] = useState({ totalRecords: 0 });
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [sourceFilter, setSourceFilter] = useState("ALL");

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) {
      router.push("/login");
      return;
    }
    fetchDataset();
  }, [router]);

  const fetchDataset = async () => {
    setLoading(true);
    try {
      const data = await getAllHealthRecords();
      setRecords(data.records || []);
      setSummary(
        data.summary || {
          totalRecords: data.records?.length || 0,
        }
      );
    } catch (error) {
      console.error("Error loading ML training dataset:", error);
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("admin");
    router.push("/login");
  };

  // Filter records based on date and source node
  const filteredRecords = useMemo(() => {
    return records.filter((rec) => {
      const search = searchTerm.toLowerCase();
      const matchesSearch = !searchTerm || rec.date?.includes(search);
      const matchesSource =
        sourceFilter === "ALL" ||
        (rec.source && rec.source.toUpperCase() === sourceFilter.toUpperCase());

      return matchesSearch && matchesSource;
    });
  }, [records, searchTerm, sourceFilter]);

  // Export JSON for Model Ingestion
  const exportAsJSON = () => {
    const dataStr =
      "data:text/json;charset=utf-8," +
      encodeURIComponent(JSON.stringify(filteredRecords, null, 2));
    const downloadAnchor = document.createElement("a");
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute(
      "download",
      `ml_telemetry_features_${new Date().toISOString().slice(0, 10)}.json`
    );
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  };

  // Export Clean CSV for ML/Pandas Feature Extraction
  const exportAsCSV = () => {
    if (filteredRecords.length === 0) return;

    const headers = [
      "Sample_ID",
      "Date",
      "Steps",
      "Distance_KM",
      "Active_Hours",
      "Active_Zone_Mins",
      "Floors",
      "Calories",
      "HeartRate_Avg",
      "Resting_HeartRate",
      "Sleep_Hours",
      "Blood_Oxygen_SpO2",
      "Body_Temp_C",
      "Weight_KG",
      "Source",
    ];

    const rows = filteredRecords.map((r) => [
      r._id || "",
      r.date || "",
      r.steps || 0,
      r.distanceWalked || 0,
      r.activeHours || 0,
      r.activeZoneMinutes || 0,
      r.floors || 0,
      r.calories || 0,
      r.heartRate || 0,
      r.restingHeartRate || 0,
      r.sleepHours || 0,
      r.bloodOxygen || 0,
      r.bodyTemperature || 0,
      r.weight || 0,
      `"${r.source || "manual"}"`,
    ]);

    const csvContent =
      "data:text/csv;charset=utf-8," +
      [headers.join(","), ...rows.map((e) => e.join(","))].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute(
      "download",
      `ml_health_features_${new Date().toISOString().slice(0, 10)}.csv`
    );
    document.body.appendChild(link);
    link.click();
    link.remove();
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
        {/* Header Control Hub */}
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-zinc-900 pb-5">
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <Database size={14} className="text-emerald-400" />
              <span className="text-[10px] font-mono tracking-[0.3em] text-zinc-500 uppercase">
                Anonymized Feature Pipeline
              </span>
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-white bg-gradient-to-b from-white to-zinc-400 bg-clip-text text-transparent">
              ML Health Training Dataset
            </h1>
            <p className="text-xs text-zinc-500 font-mono">
              Consolidated biometric telemetry parameters for AI model training and predictions.
            </p>
          </div>

          {/* Export & Actions Cluster */}
          <div className="flex flex-wrap items-center gap-2.5">
            <button
              onClick={fetchDataset}
              disabled={loading}
              className="p-2.5 bg-zinc-900  hover:bg-slate-600  rounded-xl transition-colors disabled:opacity-40"
              title="Re-query Dataset"
            >
              <RefreshCw
                size={14}
                className={`${loading ? "animate-spin text-emerald-400" : "text-zinc-400"}`}
              />
            </button>

            <button
              onClick={exportAsCSV}
              disabled={loading || filteredRecords.length === 0}
              className="flex items-center gap-1.5 px-3.5 py-2 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 rounded-xl text-xs font-mono transition-all disabled:opacity-40"
            >
              <FileSpreadsheet size={13} />
              <span>Export ML CSV</span>
            </button>

            <button
              onClick={exportAsJSON}
              disabled={loading || filteredRecords.length === 0}
              className="flex items-center gap-1.5 px-3.5 py-2 bg-cyan-500/10 hover:bg-cyan-500/20 text-cyan-400 border border-cyan-500/20 rounded-xl text-xs font-mono transition-all disabled:opacity-40"
            >
              <Download size={13} />
              <span>Export JSON</span>
            </button>
          </div>
        </div>

        {/* Dataset Metadata KPI Dashboard */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-zinc-950/40 border border-zinc-900 p-4 rounded-xl">
            <div className="flex items-center justify-between text-zinc-500 mb-2">
              <span className="text-[10px] font-mono uppercase tracking-wider">Total Training Vectors</span>
              <Database size={14} className="text-emerald-400" />
            </div>
            <div className="text-xl font-bold font-mono text-white">
              {loading ? "..." : summary.totalRecords.toLocaleString()}
            </div>
          </div>

          <div className="bg-zinc-950/40 border border-zinc-900 p-4 rounded-xl">
            <div className="flex items-center justify-between text-zinc-500 mb-2">
              <span className="text-[10px] font-mono uppercase tracking-wider">Filtered View</span>
              <Activity size={14} className="text-amber-400" />
            </div>
            <div className="text-xl font-bold font-mono text-white">
              {loading ? "..." : filteredRecords.length.toLocaleString()}
            </div>
          </div>

          <div className="bg-zinc-950/40 border border-zinc-900 p-4 rounded-xl">
            <div className="flex items-center justify-between text-zinc-500 mb-2">
              <span className="text-[10px] font-mono uppercase tracking-wider">Pipeline Status</span>
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
            </div>
            <div className="text-xs font-mono text-emerald-400 mt-1 uppercase">
              Ready For Ingestion
            </div>
          </div>
        </div>

        {/* Query & Filter Toolbar */}
        <div className="flex flex-col md:flex-row items-center justify-between gap-3 bg-zinc-950/40 border border-zinc-900 p-3 rounded-xl">
          <div className="relative w-full md:w-80">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" />
            <input
              type="text"
              placeholder="Search by date (YYYY-MM-DD)..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-zinc-900/80 border border-zinc-800 rounded-lg pl-9 pr-3 py-1.5 text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-emerald-500/50 font-mono"
            />
          </div>

          <div className="flex items-center gap-2 w-full md:w-auto justify-end font-mono text-xs">
            <span className="text-zinc-500 text-[10px] uppercase">Telemetry Source:</span>
            <select
              value={sourceFilter}
              onChange={(e) => setSourceFilter(e.target.value)}
              className="bg-zinc-900 border border-zinc-800 text-zinc-300 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-emerald-500/50 text-xs"
            >
              <option value="ALL">All Sources</option>
              <option value="Google Health Cloud API">Google Health Cloud</option>
              <option value="Fitbit API">Fitbit API</option>
              <option value="Manual">Manual Entry</option>
              <option value="Apple Health">Apple Health</option>
            </select>
          </div>
        </div>

        {/* Main Telemetry Table */}
        <div className="bg-zinc-950/40 backdrop-blur-xl border border-white/5 rounded-2xl shadow-2xl relative overflow-hidden">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-24 gap-3">
              <Loader2 className="w-8 h-8 animate-spin text-emerald-400" />
              <p className="font-mono text-xs text-zinc-500 tracking-widest uppercase animate-pulse">
                Streaming Feature Matrix...
              </p>
            </div>
          ) : filteredRecords.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 gap-2 text-zinc-500">
              <Info size={24} className="text-zinc-600" />
              <p className="font-mono text-xs tracking-wide">
                No matching health feature vectors found in the dataset.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto custom-scrollbar">
              <table className="w-full text-left border-collapse text-xs whitespace-nowrap">
                <thead>
                  <tr className="border-b border-zinc-900 bg-white/[0.01] text-zinc-400 font-mono tracking-wider uppercase text-[10px]">
                    <th className="p-4 font-semibold">Sample Hash ID</th>
                    <th className="p-4 font-semibold">Date Logged</th>
                    <th className="p-4 font-semibold">Steps & Distance</th>
                    <th className="p-4 font-semibold">Active Time / Floors</th>
                    <th className="p-4 font-semibold">Energy Output</th>
                    <th className="p-4 font-semibold">Heart Dynamics</th>
                    <th className="p-4 font-semibold">Sleep Cycle</th>
                    <th className="p-4 font-semibold">Biometrics (SpO2 / Temp)</th>
                    <th className="p-4 font-semibold">Weight</th>
                    <th className="p-4 font-semibold">Data Source</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-900/60 font-sans text-zinc-300">
                  {filteredRecords.map((rec) => (
                    <tr
                      key={rec._id}
                      className="hover:bg-white/[0.01] transition-colors duration-150 group"
                    >
                      {/* Anonymized Sample ID */}
                      <td className="p-4 font-mono text-[11px] text-zinc-500">
                        {rec._id}
                      </td>

                      {/* Date */}
                      <td className="p-4 font-mono">
                        <div className="flex items-center gap-1.5 font-bold text-zinc-200">
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
                            {rec.distanceWalked ? `${rec.distanceWalked} km` : "0 km"}
                          </span>
                        </div>
                      </td>

                      {/* Active Zone, Active Hours & Floors */}
                      <td className="p-4 font-mono text-[11px] text-zinc-400">
                        <div className="flex flex-col">
                          <span className="flex items-center gap-1 text-cyan-400">
                            <Zap size={11} />
                            {rec.activeZoneMinutes || 0} active mins
                          </span>
                          <span className="text-[10px] text-zinc-500 flex items-center gap-1 mt-0.5">
                            <Clock size={10} />
                            {rec.activeHours || 0} hrs active | {rec.floors || 0} floors
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

                      {/* Heart Dynamics */}
                      <td className="p-4 font-mono">
                        <div className="flex flex-col text-[11px]">
                          <span className="flex items-center gap-1 text-rose-400">
                            <Heart size={12} />
                            Avg: {rec.heartRate || 0} bpm
                          </span>
                          <span className="text-[10px] text-zinc-500 mt-0.5">
                            Resting: {rec.restingHeartRate || 0} bpm
                          </span>
                        </div>
                      </td>

                      {/* Sleep */}
                      <td className="p-4 font-mono">
                        <div className="flex items-center gap-1 text-indigo-300">
                          <Moon size={12} className="text-indigo-400" />
                          <span>{rec.sleepHours ? `${rec.sleepHours} hrs` : "0 hrs"}</span>
                        </div>
                      </td>

                      {/* Biometrics */}
                      <td className="p-4 font-mono text-[11px] text-zinc-400">
                        <div className="flex flex-col">
                          <span>SpO2: {rec.bloodOxygen ? `${rec.bloodOxygen}%` : "0%"}</span>
                          <span className="text-[10px] text-zinc-500 flex items-center gap-0.5 mt-0.5">
                            <Thermometer size={10} />
                            {rec.bodyTemperature ? `${rec.bodyTemperature} °C` : "0 °C"}
                          </span>
                        </div>
                      </td>

                      {/* Weight */}
                      <td className="p-4 font-mono text-zinc-400">
                        <div className="flex items-center gap-1">
                          <Scale size={12} className="text-zinc-500" />
                          <span>{rec.weight ? `${rec.weight} kg` : "0 kg"}</span>
                        </div>
                      </td>

                      {/* Source */}
                      <td className="p-4 font-mono text-[11px]">
                        <span className="px-2 py-0.5 rounded bg-zinc-900 border border-zinc-800 text-zinc-400 uppercase">
                          {rec.source || "Manual"}
                        </span>
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