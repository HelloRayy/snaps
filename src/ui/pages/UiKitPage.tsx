import React, { useState } from 'react';
import {
  ArrowLeft,
  Copy,
  Check,
  Search,
  SlidersHorizontal,
  Moon,
  Sun,
  Code2,
  Heart,
  MessageCircle,
  Repeat,
  Share2,
  Sparkles,
  MapPin,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  PackageCheck,
} from 'lucide-react';
import { triggerHaptic } from '@/utils/haptics';
import { SnapsLogoSvg } from '@/ui/components/brand/SnapsLogoSvg';
import { ButtonPrimary } from '@/ui/components/ui/ButtonPrimary';
import { ButtonSecondary } from '@/ui/components/ui/ButtonSecondary';
import { Input } from '@/ui/components/ui/Input';
import { Badge } from '@/ui/components/ui/Badge';
import { Card } from '@/ui/components/ui/Card';
import { Checkbox } from '@/ui/components/ui/Checkbox';

interface UiKitPageProps {
  onBack: () => void;
}

export const UiKitPage: React.FC<UiKitPageProps> = ({ onBack }) => {
  const [activeTab, setActiveTab] = useState<'tokens' | 'buttons' | 'inputs' | 'cards' | 'badges'>('tokens');
  const [isDarkMode, setIsDarkMode] = useState(false);
  const [copiedHex, setCopiedHex] = useState<string | null>(null);
  const [inputVal, setInputVal] = useState('SMKN 8 Semarang');
  const [checkboxVal, setCheckboxVal] = useState(true);
  const [activeChip, setActiveChip] = useState('Semua');

  const copyToClipboard = (hex: string) => {
    triggerHaptic('light');
    navigator.clipboard?.writeText(hex);
    setCopiedHex(hex);
    setTimeout(() => setCopiedHex(null), 2000);
  };

  const tabs = [
    { id: 'tokens', label: 'Tokens' },
    { id: 'buttons', label: 'Buttons & CTA' },
    { id: 'inputs', label: 'Inputs & Form' },
    { id: 'cards', label: 'Cards & Feed' },
    { id: 'badges', label: 'Badges & Status' },
  ] as const;

  return (
    <div className={`min-h-screen transition-colors duration-200 ${isDarkMode ? 'bg-[#0f1115] text-[#f8fafc]' : 'bg-[#f8f9fa] text-[#0f172a]'}`}>
      {/* Top Header bar */}
      <header className={`sticky top-0 z-40 border-b backdrop-blur-md transition-colors ${isDarkMode ? 'bg-[#0f1115]/90 border-[#1f242d]' : 'bg-white/90 border-slate-200'}`}>
        <div className="max-w-4xl mx-auto px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button
              onClick={() => {
                triggerHaptic('light');
                onBack();
              }}
              className={`p-2 rounded-full transition-colors ${isDarkMode ? 'hover:bg-white/10 text-white' : 'hover:bg-slate-100 text-slate-700'}`}
              aria-label="Kembali"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
            <div className="flex items-center gap-2">
              <SnapsLogoSvg className="h-6 w-auto" />
              <span className="font-bold text-base tracking-tight">UI Kit & Design System</span>
              <span className="text-[10px] font-semibold bg-[#3d38f5]/10 text-[#3d38f5] px-2 py-0.5 rounded-full">v1.0</span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => {
                triggerHaptic('light');
                setIsDarkMode(!isDarkMode);
              }}
              className={`p-2 rounded-full border transition-colors ${
                isDarkMode ? 'bg-[#1b2028] border-[#2a303c] text-amber-400' : 'bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100'
              }`}
              title="Toggle Dark/Light Mode"
            >
              {isDarkMode ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>
          </div>
        </div>

        {/* M3 Style Tab Bar */}
        <div className="max-w-4xl mx-auto px-4 overflow-x-auto scrollbar-none flex gap-2">
          {tabs.map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => {
                  triggerHaptic('light');
                  setActiveTab(tab.id);
                }}
                className={`py-3 px-3.5 text-xs font-semibold whitespace-nowrap border-b-2 transition-all ${
                  isActive
                    ? 'border-[#3d38f5] text-[#3d38f5]'
                    : isDarkMode
                    ? 'border-transparent text-slate-400 hover:text-slate-200'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                {tab.label}
              </button>
            );
          })}
        </div>
      </header>

      {/* Main Content Area */}
      <main className="max-w-4xl mx-auto px-4 py-6 space-y-6">
        {/* TAB 1: DESIGN TOKENS */}
        {activeTab === 'tokens' && (
          <div className="space-y-6">
            <section className={`p-6 rounded-2xl border transition-colors ${isDarkMode ? 'bg-[#14171d] border-[#222733]' : 'bg-white border-slate-200 shadow-sm'}`}>
              <div className="mb-4">
                <h2 className="text-base font-bold">Color Tokens & Brand Palette</h2>
                <p className={`text-xs mt-1 ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`}>
                  Electric Indigo (#3d38f5) sebagai signature brand Snaps, lengkap dengan slate ink & status semantic. Tap untuk salin hex.
                </p>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {[
                  { name: 'Primary (Electric Indigo)', hex: '#3d38f5', bg: 'bg-[#3d38f5]', text: 'text-white' },
                  { name: 'Primary Dark (Hover)', hex: '#312bd9', bg: 'bg-[#312bd9]', text: 'text-white' },
                  { name: 'Pastel Indigo', hex: '#eef0ff', bg: 'bg-[#eef0ff]', text: 'text-[#3d38f5]' },
                  { name: 'Success Emerald', hex: '#10b981', bg: 'bg-[#10b981]', text: 'text-white' },
                  { name: 'Warning Amber', hex: '#f59e0b', bg: 'bg-[#f59e0b]', text: 'text-white' },
                  { name: 'Error Rose', hex: '#ef4444', bg: 'bg-[#ef4444]', text: 'text-white' },
                  { name: 'Slate Ink (Light)', hex: '#1a1a1a', bg: 'bg-[#1a1a1a]', text: 'text-white' },
                  { name: 'Dark Surface (OLED)', hex: '#161717', bg: 'bg-[#161717]', text: 'text-slate-300' },
                ].map((c) => (
                  <button
                    key={c.hex}
                    onClick={() => copyToClipboard(c.hex)}
                    className={`p-3 rounded-xl border text-left flex flex-col justify-between h-24 transition-all hover:scale-[1.02] ${
                      isDarkMode ? 'border-[#262c3a] bg-[#1a1f29]' : 'border-slate-100 bg-slate-50'
                    }`}
                  >
                    <div className={`w-full h-8 rounded-lg ${c.bg} flex items-center justify-end px-2`}>
                      {copiedHex === c.hex && <Check className="w-3.5 h-3.5 text-white" />}
                    </div>
                    <div>
                      <div className="text-[11px] font-bold truncate">{c.name}</div>
                      <div className="text-[10px] font-mono text-slate-400">{c.hex}</div>
                    </div>
                  </button>
                ))}
              </div>
            </section>

            <section className={`p-6 rounded-2xl border transition-colors ${isDarkMode ? 'bg-[#14171d] border-[#222733]' : 'bg-white border-slate-200 shadow-sm'}`}>
              <div className="mb-4">
                <h2 className="text-base font-bold">Typography Scale (SFPro / Inter)</h2>
                <p className={`text-xs mt-1 ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`}>
                  Standar teks Snaps mulai dari judul hingga label timestamp.
                </p>
              </div>

              <div className="space-y-4 divide-y divide-slate-100 dark:divide-slate-800">
                <div className="pt-2">
                  <div className="text-[11px] font-mono text-[#3d38f5] mb-1">Display Title (24px • Bold)</div>
                  <div className="text-2xl font-bold tracking-tight">Snaps Market SMKN 8 Semarang</div>
                </div>
                <div className="pt-3">
                  <div className="text-[11px] font-mono text-[#3d38f5] mb-1">Title Medium (17px • Bold)</div>
                  <div className="text-[17px] font-bold">Timeline Diskusi Siswa</div>
                </div>
                <div className="pt-3">
                  <div className="text-[11px] font-mono text-[#3d38f5] mb-1">Body Regular (14.5px • Regular)</div>
                  <div className="text-[14.5px] leading-relaxed opacity-90">
                    Ada yang punya modul DKV semester 2 nggak? Mau beli preloved nih buat referensi tugas proyek semester.
                  </div>
                </div>
                <div className="pt-3">
                  <div className="text-[11px] font-mono text-[#3d38f5] mb-1">Tabular Price (16px • Semibold)</div>
                  <div className="text-base font-semibold font-mono text-[#3d38f5]">Rp 45.000</div>
                </div>
              </div>
            </section>
          </div>
        )}

        {/* TAB 2: BUTTONS & CTA */}
        {activeTab === 'buttons' && (
          <div className="space-y-6">
            <section className={`p-6 rounded-2xl border transition-colors ${isDarkMode ? 'bg-[#14171d] border-[#222733]' : 'bg-white border-slate-200 shadow-sm'}`}>
              <div className="mb-4">
                <h2 className="text-base font-bold">Kumo / Primary Button Variants</h2>
                <p className={`text-xs mt-1 ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`}>
                  Pill capsule buttons dengan tinggi 48-52px, micro-interaction scale, dan haptic tactile response.
                </p>
              </div>

              <div className="max-w-md space-y-3">
                <div>
                  <div className="text-[11px] font-mono text-slate-400 mb-1.5">Primary (Full Pill • Brand Signature)</div>
                  <ButtonPrimary onClick={() => triggerHaptic('light')}>
                    Button Primary (#3d38f5)
                  </ButtonPrimary>
                </div>
                <div>
                  <div className="text-[11px] font-mono text-slate-400 mb-1.5">Secondary (Soft Slate Pill)</div>
                  <ButtonSecondary onClick={() => triggerHaptic('light')}>
                    Button Secondary (#ededed)
                  </ButtonSecondary>
                </div>
                <div>
                  <div className="text-[11px] font-mono text-slate-400 mb-1.5">Category Filter Chips</div>
                  <div className="flex flex-wrap gap-2 pt-1">
                    {['Semua', 'PPLG', 'DKV', 'Kuliner', 'Preloved'].map((chip) => {
                      const isSel = activeChip === chip;
                      return (
                        <button
                          key={chip}
                          onClick={() => {
                            triggerHaptic('light');
                            setActiveChip(chip);
                          }}
                          className={`px-4 py-1.5 rounded-full text-xs font-semibold transition-all ${
                            isSel
                              ? 'bg-[#3d38f5] text-white shadow-sm'
                              : isDarkMode
                              ? 'bg-[#1e232d] text-slate-300 hover:bg-[#282e3b]'
                              : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                          }`}
                        >
                          {chip}
                        </button>
                      );
                    })}
                  </div>
                </div>
              </div>
            </section>
          </div>
        )}

        {/* TAB 3: INPUTS & FORM */}
        {activeTab === 'inputs' && (
          <div className="space-y-6">
            <section className={`p-6 rounded-2xl border transition-colors ${isDarkMode ? 'bg-[#14171d] border-[#222733]' : 'bg-white border-slate-200 shadow-sm'}`}>
              <div className="mb-4">
                <h2 className="text-base font-bold">Form Controls & Search Bar</h2>
                <p className={`text-xs mt-1 ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`}>
                  Input field rounded dengan background netral dan border kontras ramah sentuhan.
                </p>
              </div>

              <div className="max-w-md space-y-4">
                <div>
                  <label className="block text-xs font-semibold mb-1">Standard Text Input</label>
                  <Input
                    value={inputVal}
                    onChange={(e) => setInputVal(e.target.value)}
                    placeholder="Masukkan nama lengkap..."
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold mb-1">Search Bar Capsule</label>
                  <div className="relative">
                    <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      type="text"
                      placeholder="Cari barang atau thread..."
                      className={`w-full pl-10 pr-4 py-2.5 rounded-full text-xs font-medium border outline-none transition-all ${
                        isDarkMode
                          ? 'bg-[#1a1f29] border-[#29303e] text-white focus:border-[#3d38f5]'
                          : 'bg-slate-50 border-slate-200 text-slate-800 focus:border-[#3d38f5]'
                      }`}
                    />
                  </div>
                </div>

                <div className="pt-2">
                  <Checkbox
                    id="cod-terms"
                    checked={checkboxVal}
                    onChange={(e) => setCheckboxVal(e.target.checked)}
                    label="Saya setuju bertemu di Spot COD sekolah"
                  />
                </div>
              </div>
            </section>
          </div>
        )}

        {/* TAB 4: CARDS & FEED */}
        {activeTab === 'cards' && (
          <div className="space-y-6">
            <section className={`p-6 rounded-2xl border transition-colors ${isDarkMode ? 'bg-[#14171d] border-[#222733]' : 'bg-white border-slate-200 shadow-sm'}`}>
              <div className="mb-4">
                <h2 className="text-base font-bold">Feed Post Card (Threads Spec)</h2>
                <p className={`text-xs mt-1 ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`}>
                  Kartu postingan thread dengan avatar inisial, verified badge, teks isi, dan action bar.
                </p>
              </div>

              <div className="max-w-lg">
                <div className={`p-4 rounded-2xl border ${isDarkMode ? 'bg-[#181c24] border-[#262c3a]' : 'bg-white border-slate-200 shadow-sm'}`}>
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-[#3d38f5]/10 text-[#3d38f5] flex items-center justify-center font-bold text-sm">
                      AP
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-1.5">
                        <span className="font-bold text-xs">Alya Putri DKV</span>
                        <span className="w-3.5 h-3.5 bg-[#3d38f5] rounded-full text-white text-[9px] flex items-center justify-center font-bold">✓</span>
                        <span className="text-[11px] text-slate-400 ml-auto">15m lalu</span>
                      </div>
                      <div className="text-[10px] text-slate-400">@alyaputri • XII DKV 2</div>
                      <p className="mt-2 text-xs leading-relaxed">
                        Siap terima pesanan totebag canvas sablon custom hasil praktik unit produksi DKV! Minat COD bisa di Gazebo Depan ya ✨
                      </p>
                      <div className="mt-3 flex items-center gap-5 text-slate-400 text-xs">
                        <button className="flex items-center gap-1 hover:text-[#ef4444] transition-colors">
                          <Heart className="w-4 h-4" /> <span>32</span>
                        </button>
                        <button className="flex items-center gap-1 hover:text-[#3d38f5] transition-colors">
                          <MessageCircle className="w-4 h-4" /> <span>8</span>
                        </button>
                        <button className="flex items-center gap-1 hover:text-[#10b981] transition-colors">
                          <Repeat className="w-4 h-4" /> <span>4</span>
                        </button>
                        <button className="ml-auto hover:text-slate-600 transition-colors">
                          <Share2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Spot Card */}
                <div className={`mt-4 p-3.5 rounded-xl border flex items-center gap-3 ${isDarkMode ? 'bg-[#181c24] border-[#262c3a]' : 'bg-white border-slate-200'}`}>
                  <div className="w-10 h-10 rounded-xl bg-[#3d38f5]/10 text-[#3d38f5] flex items-center justify-center">
                    <MapPin className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="text-xs font-bold">Gazebo Depan Bengkel PPLG</div>
                    <div className="text-[10px] text-slate-400">Zona Aman Titik Temu COD Kampus SMKN 8</div>
                  </div>
                </div>
              </div>
            </section>
          </div>
        )}

        {/* TAB 5: BADGES & STATUS */}
        {activeTab === 'badges' && (
          <div className="space-y-6">
            <section className={`p-6 rounded-2xl border transition-colors ${isDarkMode ? 'bg-[#14171d] border-[#222733]' : 'bg-white border-slate-200 shadow-sm'}`}>
              <div className="mb-4">
                <h2 className="text-base font-bold">Status Badges & Verification Tags</h2>
                <p className={`text-xs mt-1 ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`}>
                  Label status pesanan, verifikasi siswa SMKN 8, dan jurusan.
                </p>
              </div>

              <div className="flex flex-wrap gap-2.5">
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-[#10b981]/10 text-[#10b981]">
                  <CheckCircle2 className="w-3.5 h-3.5" /> COD Selesai
                </span>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-[#f59e0b]/10 text-[#f59e0b]">
                  <AlertTriangle className="w-3.5 h-3.5" /> Menunggu COD
                </span>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-[#ef4444]/10 text-[#ef4444]">
                  <XCircle className="w-3.5 h-3.5" /> Dibatalkan
                </span>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-[#3d38f5]/10 text-[#3d38f5]">
                  <Sparkles className="w-3.5 h-3.5" /> Terverifikasi NIS
                </span>
              </div>
            </section>
          </div>
        )}
      </main>
    </div>
  );
};
