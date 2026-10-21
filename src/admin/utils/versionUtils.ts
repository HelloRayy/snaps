export interface ParsedAppVersion {
  raw: string;
  versionName: string;
  versionCode: number | null;
  normalizedBuildNumber: number | null;
  semverParts: number[];
}

/**
 * Mem-parse string versi aplikasi (contoh: "v1.0.38+2041", "1.0.39+42", "v1.0.35")
 */
export function parseAppVersion(versionStr?: string | null): ParsedAppVersion | null {
  if (!versionStr || typeof versionStr !== 'string') return null;
  const trimmed = versionStr.trim();
  if (!trimmed || trimmed === '-' || trimmed.toLowerCase() === 'null') return null;

  // Split berdasarkan '+' jika ada (nama rilis + kode build)
  const plusIdx = trimmed.indexOf('+');
  let namePart = plusIdx >= 0 ? trimmed.slice(0, plusIdx) : trimmed;
  const codePart = plusIdx >= 0 ? trimmed.slice(plusIdx + 1) : null;

  // Bersihkan prefiks 'v' atau 'V'
  namePart = namePart.replace(/^v/i, '').trim();

  // Ekstrak angka semver (contoh: "1.0.39" -> [1, 0, 39])
  const semverParts = namePart
    .split('.')
    .map((p) => {
      const n = parseInt(p.replace(/[^0-9]/g, ''), 10);
      return isNaN(n) ? 0 : n;
    });

  let versionCode: number | null = null;
  let normalizedBuildNumber: number | null = null;

  if (codePart) {
    const parsedCode = parseInt(codePart.replace(/[^0-9]/g, ''), 10);
    if (!isNaN(parsedCode)) {
      versionCode = parsedCode;
      // Normalisasi build code (misal 2042 dan 42 merujuk pada build number yang sama)
      normalizedBuildNumber = parsedCode >= 1000 ? parsedCode % 1000 : parsedCode;
    }
  }

  return {
    raw: trimmed,
    versionName: namePart,
    versionCode,
    normalizedBuildNumber,
    semverParts,
  };
}

/**
 * Membandingkan dua versi aplikasi.
 * Return:
 *   > 0 jika a lebih baru dari b
 *   < 0 jika a lebih lama dari b
 *   0 jika a dan b setara
 */
export function compareAppVersions(
  a: string | ParsedAppVersion | null | undefined,
  b: string | ParsedAppVersion | null | undefined
): number {
  const pA = typeof a === 'string' ? parseAppVersion(a) : a;
  const pB = typeof b === 'string' ? parseAppVersion(b) : b;

  if (!pA && !pB) return 0;
  if (!pA) return -1;
  if (!pB) return 1;

  // 1. Bandingkan komponen SemVer (Mayor.Minor.Patch)
  const maxLen = Math.max(pA.semverParts.length, pB.semverParts.length);
  for (let i = 0; i < maxLen; i++) {
    const valA = pA.semverParts[i] ?? 0;
    const valB = pB.semverParts[i] ?? 0;
    if (valA > valB) return 1;
    if (valA < valB) return -1;
  }

  // 2. Jika SemVer identik, bandingkan normalized build number
  if (pA.normalizedBuildNumber !== null && pB.normalizedBuildNumber !== null) {
    if (pA.normalizedBuildNumber > pB.normalizedBuildNumber) return 1;
    if (pA.normalizedBuildNumber < pB.normalizedBuildNumber) return -1;
  } else if (pA.versionCode !== null && pB.versionCode !== null) {
    if (pA.versionCode > pB.versionCode) return 1;
    if (pA.versionCode < pB.versionCode) return -1;
  }

  return 0;
}

/**
 * Mengecek apakah versi aplikasi pengguna lebih lama dari versi target terbaru.
 */
export function isAppVersionOutdated(
  userVersion: string | null | undefined,
  latestVersion: string | null | undefined
): boolean {
  if (!userVersion || !latestVersion) return false;
  return compareAppVersions(userVersion, latestVersion) < 0;
}

/**
 * Mencari string versi tertinggi dari daftar versi yang diberikan.
 */
export function findHighestVersion(versions: (string | null | undefined)[]): string | null {
  let highest: ParsedAppVersion | null = null;
  for (const v of versions) {
    const parsed = parseAppVersion(v);
    if (!parsed) continue;
    if (!highest || compareAppVersions(parsed, highest) > 0) {
      highest = parsed;
    }
  }
  return highest ? highest.raw : null;
}

/**
 * Menentukan versi rilis efektif paling mutakhir (menggabungkan data server dan data lokal siswa).
 */
export function getEffectiveLatestVersion(
  serverLatest: string | null | undefined,
  userVersions?: (string | null | undefined)[]
): string | null {
  const highestUser = userVersions ? findHighestVersion(userVersions) : null;
  if (!serverLatest) return highestUser;
  if (!highestUser) return serverLatest;
  return compareAppVersions(serverLatest, highestUser) >= 0 ? serverLatest : highestUser;
}
