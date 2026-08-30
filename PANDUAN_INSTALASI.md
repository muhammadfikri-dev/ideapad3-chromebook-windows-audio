# 📖 PANDUAN LENGKAP INSTALASI DRIVER AUDIO CHROMEBOOK LENOVO IDEAPAD 3 11IGL05 (WINDOWS 10 64-BIT)

Panduan ini ditujukan bagi pengguna Chromebook **Lenovo IdeaPad 3 11IGL05** (Board: **`LICK`**, Baseboard: **`Octopus`**, Prosesor: **Intel Celeron N4020**) yang telah diinstal **Windows 10 64-bit**.

---

## 📌 1. Mengapa Chromebook Memerlukan Driver Audio Khusus?

Chromebook tidak menggunakan kartu suara standar seperti laptop Windows pada umumnya (yang biasanya menggunakan Realtek High Definition Audio standar). Sebaliknya, Chromebook menggunakan arsitektur **Intel Smart Sound Technology (SST) / Sound Open Firmware (SOF)** dengan jalur bus I2S dan amplifier digital terpisah:
- **Audio Controller**: Intel Gemini Lake HD Audio Controller (`PCI\VEN_8086&DEV_3198`)
- **Speaker Internal**: Maxim MAX98357A I2S Amplifier (`ACPI\MX98357A`)
- **Headphone & Mic Jack**: Dialog Semiconductor DA7219 Codec (`ACPI\DLGS7219`) atau Realtek ALC5682 (`ACPI\10EC5682`)

Tanpa driver khusus ini, Windows 10 tidak akan mengenali speaker internal dan jack audio laptop Anda (sering kali muncul tanda silang merah pada ikon speaker di taskbar).

---

## ⚙️ 2. Prasyarat Sistem

1. **UEFI Firmware**: Laptop telah menggunakan UEFI Full ROM dari MrChromebox.
2. **Sistem Operasi**: Windows 10 64-bit (Versi 20H2, 21H1, 21H2, 22H2 atau lebih baru).
3. **Koneksi Internet** (hanya diperlukan saat pertama kali menjalankan GitHub Actions).

---

## 🚀 3. Cara Meng-Compile Driver dengan GitHub Actions

Anda **tidak perlu** menginstal Visual Studio atau Windows Driver Kit (WDK) yang berukuran belasan GB di laptop Anda. Seluruh proses kompilasi dilakukan di cloud secara otomatis oleh **GitHub Actions**:

### Langkah-langkah:
1. **Buat Repositori di GitHub**:
   - Buka [GitHub.com](https://github.com) dan buat repositori baru (misalnya `ideapad3-chromebook-windows-audio`).
2. **Unggah (Push) Kode ke GitHub**:
   Buka Terminal / PowerShell di folder proyek ini dan jalankan:
   ```bash
   git init
   git add .
   git commit -m "Build audio drivers for Lenovo IdeaPad 3 11IGL05"
   git branch -M main
   git remote add origin https://github.com/<USERNAME-ANDA>/<NAMA-REPO-ANDA>.git
   git push -u origin main
   ```
3. **Jalankan Alur Kerja (Workflow)**:
   - Masuk ke halaman repositori di GitHub.
   - Klik tab **Actions** di bagian atas.
   - Pilih workflow **Build and Package Lenovo IdeaPad 3 11IGL05 Audio Drivers**.
   - Klik tombol **Run workflow** -> pilih branch `main` -> klik **Run workflow**.
4. **Unduh Paket Driver**:
   - Tunggu sekitar 2 - 4 menit hingga proses build selesai (muncul centang hijau `Build & Package Audio Drivers`).
   - Klik pada hasil build tersebut.
   - Di bagian bawah (**Artifacts**), unduh file **`Lenovo-IdeaPad3-11IGL05-Audio-Drivers-x64.zip`**.

---

## 📥 4. Langkah Instalasi di Windows 10

Setelah mengunduh file `Lenovo-IdeaPad3-11IGL05-Audio-Drivers-x64.zip`:

### Langkah 1: Ekstrak File
1. Klik kanan file `.zip` yang telah diunduh, lalu pilih **Extract All...** (Ekstrak Semua).
2. Buka folder hasil ekstraksi.

### Langkah 2: Jalankan Installer Otomatis
1. Cari file bernama **`Install-Audio-Drivers.bat`**.
2. **Klik kanan** pada file tersebut, lalu pilih **Run as Administrator** (Jalankan sebagai administrator).
3. Jendela command prompt dan PowerShell akan terbuka dan melakukan hal-hal berikut secara otomatis:
   - ✅ Mengaktifkan **Windows TestSigning Mode** (diperlukan agar Windows mengizinkan driver kernel kustom).
   - ✅ Menginstal sertifikat digital keamanan ke Windows Certificate Store.
   - ✅ Memasang driver `sklhdaudbus.inf` (Bus Audio Intel Gemini Lake).
   - ✅ Memasang driver `max98357a.inf` (Amplifier Speaker Laptop).
   - ✅ Memasang driver `da7219.inf` / `rt5682.inf` (Codec Headphone & Mic).
   - ✅ Merestart layanan audio Windows (`Audiosrv`).

### Langkah 3: Restart Laptop
1. Setelah muncul pesan **Proses instalasi selesai**, tekan sembarang tombol untuk menutup jendela.
2. **Restart** laptop Lenovo IdeaPad 3 Anda.

---

## 🔊 5. Verifikasi Suara

Setelah laptop menyala kembali:
1. Periksa ikon speaker di pojok kanan bawah taskbar. Ikon silang merah seharusnya sudah hilang.
2. Klik ikon speaker dan coba atur volume.
3. Putar video di YouTube atau file musik untuk menguji suara speaker internal.
4. Tancapkan headset/earphone ke jack audio 3.5mm untuk menguji peralihan otomatis ke headphone dan mikrofon.

---

## 🛠️ 6. Troubleshooting (Pemecahan Masalah)

### Masalah 1: Suara masih bertanda silang atau tidak muncul perangkat output
- Jalankan file **`Troubleshoot-Audio.ps1`** dengan klik kanan -> **Run with PowerShell** (atau lewat PowerShell Administrator).
- Tool ini akan memindai seluruh status perangkat audio dan menghasilkan laporan `audio_diag_report.txt`.

### Masalah 2: Device Manager menunjukkan kode error 52 (Driver signature issue)
- Hal ini terjadi jika Windows TestSigning belum aktif.
- Jalankan file **`Enable-TestSigning.bat`** (Run as Administrator).
- Lakukan **Restart** laptop.

### Masalah 3: Speaker belum berbunyi namun Headphone berfungsi
- Buka **Device Manager** (`Win + X` -> Device Manager).
- Cari kategori **System devices** dan pastikan **Maxim 98357a I2S Amplifier** berstatus "This device is working properly".
- Jika belum, klik kanan -> **Update driver** -> **Browse my computer for drivers** -> arahkan ke folder `02-Maxim-Speaker-Amp`.

---

## 📞 Ringkasan Perintah Penting (Manual via CMD/PowerShell Admin)

Jika Anda ingin melakukan konfigurasi manual:
```powershell
# 1. Aktifkan TestSigning
bcdedit /set testsigning on
bcdedit /set nointegritychecks on

# 2. Pasang Sertifikat
Import-Certificate -FilePath ".\Certificates\ChromebookAudioDriverTestCert.cer" -CertStoreLocation "Cert:\LocalMachine\Root"
Import-Certificate -FilePath ".\Certificates\ChromebookAudioDriverTestCert.cer" -CertStoreLocation "Cert:\LocalMachine\TrustedPublisher"

# 3. Pasang Driver
pnputil /add-driver .\01-Intel-HD-Audio-Bus\sklhdaudbus.inf /install
pnputil /add-driver .\02-Maxim-Speaker-Amp\max98357a.inf /install
pnputil /add-driver .\03-DA7219-Headphone-Mic\da7219.inf /install
pnputil /add-driver .\04-RT5682-Headphone-Mic\rt5682.inf /install

# 4. Restart Audio Service
Restart-Service Audiosrv -Force
```
