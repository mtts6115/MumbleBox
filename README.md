# 🎙️ MumbleBox

> **Turnkey Mumble Voice Server for Android TV Box & ARM Linux Devices**  
> เปลี่ยนกล่อง Android TV Box ให้กลายเป็นเซิร์ฟเวอร์สื่อสารเสียงส่วนตัว (Mumble / Murmur) ความหน่วงต่ำ คุณภาพเสียงชัดใส ติดตั้งง่ายในคำสั่งเดียว

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Android / Termux](https://img.shields.io/badge/Platform-Android%20%7C%20Termux-3DDC84.svg?logo=android&logoColor=white)](#)
[![Platform: Linux / Armbian](https://img.shields.io/badge/Platform-Armbian%20%7C%20Linux-E95420.svg?logo=ubuntu&logoColor=white)](#)
[![Mumble Server: Murmur](https://img.shields.io/badge/Server-Murmur%20(Mumble)-blue.svg)](#)

---

## ✨ คุณสมบัติเด่น (Features)

- ⚡ **One-Command Setup:** ติดตั้งทุกอย่างจบในสคริปต์เดียว ไม่ต้องพิมพ์คำสั่งคอมไพล์หรือตั้งค่าคอนฟิกยาวเหยียด
- 📱 **ไม่ต้องรูท (No Root Needed):** ใช้งานบนกล่อง Android ทั่วไปได้ทันทีผ่าน Termux + PRoot
- 🖥️ **รองรับ Armbian / Linux ด้วย:** หากกล่องถูกแฟลชเป็น Linux หรือ Armbian ระบบจะตรวจจับและสลับเป็น Native Mode พร้อม Systemd อัตโนมัติ
- 🛠️ **CLI ควบคุมในตัว (`mumblebox`):** คำสั่งลัดจัดการระบบ เช่น `mumblebox status`, `mumblebox info`, `mumblebox logs`, `mumblebox passwd`
- 🔋 **Android Background Guard:** ป้องกันไม่ให้ Android สั่ง Sleep หรือตัดการทำงานด้วย `termux-wake-lock`
- 🔄 **Auto-Start on Boot:** รองรับการเปิดเซิร์ฟเวอร์ขึ้นมาเองทันทีที่เสียบปลั๊กกล่อง (ผ่าน Termux:Boot หรือ Systemd)
- 🔒 **SuperUser Management:** สร้างและเปลี่ยนรหัสแอดมินได้สะดวกรวดเร็ว
- 🌐 **Network Discovery:** แสดงผล IP ภายในบ้าน (LAN), IP นอกบ้าน (WAN) และ Direct Join Link `mumble://` ทันทีหลังติดตั้งเสร็จ

---

## 🚀 วิธีติดตั้งอย่างรวดเร็ว (Quick Start)

### วิธีที่ 1: บน Android TV Box (ผ่านแอป Termux)

1. ดาวน์โหลดและติดตั้ง **Termux** จาก [F-Droid](https://f-droid.org/packages/com.termux/) หรือ [Termux GitHub Releases](https://github.com/termux/termux-app/releases) *(อย่าโหลดจาก Google Play Store เพราะเวอร์ชันเก่าและหยุดอัปเดต)*
2. เปิดแอป Termux แล้วคัดลอกคำสั่งด้านล่างไปวาง:

```bash
pkg install -y git curl && git clone https://github.com/mtts6115/MumbleBox.git && cd mumblebox && bash install.sh
```
*(หรือหากอัปโหลดขึ้น GitHub แล้ว สามารถใช้ `curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash` ได้ทันที)*

3. ระบบจะมี Wizard ให้กรอก:
   - **ชื่อเซิร์ฟเวอร์ (Server Name)**
   - **พอร์ต (Port)** (ค่าเริ่มต้น: 64738)
   - **จำนวนผู้ใช้สูงสุด (Max Users)**
   - **รหัสผ่านแอดมิน (SuperUser Password)**
4. ติดตั้งเสร็จสิ้น! เซิร์ฟเวอร์จะเริ่มทำงานทันที พร้อมแสดง IP และลิงก์สำหรับเข้าใช้งาน

---

### วิธีที่ 2: บน Armbian / Debian / Ubuntu Box

หากกล่องของคุณใช้ชิป Amlogic/Rockchip และแฟลชเป็น Armbian:
```bash
git clone https://github.com/mtts6115/MumbleBox.git
cd mumblebox
sudo bash install.sh
```

---

## 🕹️ คำสั่งการใช้งาน (CLI Management)

หลังจากติดตั้งแล้ว คุณสามารถพิมพ์คำสั่ง `mumblebox` ในหน้าต่าง Terminal ได้ตลอดเวลา:

| คำสั่ง | ความสามารถ |
|---|---|
| `mumblebox status` | ดูสถานะการทำงาน, PID, และอัตราการกินแรม (RAM Usage) |
| `mumblebox info` | ดู IP Address ในบ้าน/นอกบ้าน, พอร์ต และลิงก์เข้าเซิร์ฟเวอร์ (`mumble://`) |
| `mumblebox start` | สั่งเปิดเซิร์ฟเวอร์ Mumble |
| `mumblebox stop` | สั่งปิดเซิร์ฟเวอร์ |
| `mumblebox restart` | สั่งรีสตาร์ตเซิร์ฟเวอร์ใหม่ |
| `mumblebox logs` | เปิดดูบันทึกการทำงานแบบ Real-time (tail -f) |
| `mumblebox passwd` | เปลี่ยนรหัสผ่านผู้ดูแลระบบ (SuperUser) |
| `mumblebox config` | เปิดแก้ไขไฟล์คอนฟิก `mumble-server.ini` |
| `mumblebox backup` | บันทึกสำรองข้อมูลการตั้งค่าและห้องทั้งหมดเป็นไฟล์ `.tar.gz` |

---

## 🌐 การตั้งค่าเครือข่าย & ให้เพื่อนจากนอกบ้านเชื่อมต่อ

### 1. เชื่อมต่อภายในบ้าน (Local LAN)
- ใช้ IP ภายในบ้าน เช่น `192.168.1.xxx:64738`
- ทุกคนที่ต่อ Wi-Fi หรือ LAN เดียวกันสามารถกดเข้าได้ทันที

### 2. ให้เพื่อนนอกบ้านเชื่อมต่อเข้ามา (Internet Access)
เลือกวิธีใดวิธีหนึ่งต่อไปนี้:

* **วิธี Port Forwarding (แนะนำสำหรับบ้านที่มี Public IP / DDNS):**
  1. ล็อกอินเข้าเราเตอร์อินเทอร์เน็ตบ้าน (Wi-Fi Router)
  2. ไปที่เมนู **Port Forwarding / Virtual Server**
  3. Forward พอร์ต **`64738`** (ทั้งโปรโตคอล **TCP** และ **UDP**) ชี้ไปยัง Local IP ของกล่อง Android Box
  4. แจ้ง Public IP หรือชื่อ Host DDNS ให้เพื่อนเชื่อมต่อ
* **วิธีใช้ Mesh VPN (Tailscale / ZeroTier - ไม่ต้องเปิดพอร์ต):**
  1. ลงแอป **Tailscale** บนกล่อง Android Box และเครื่องเพื่อน
  2. ต่อเข้าเครือข่ายเดียวกัน จะได้ IP วงเสมือน (เช่น `100.x.x.x`)
  3. ใช้ IP นั้นเชื่อมต่อได้ทันที ทะลุไฟร์วอลล์และ CGNAT ได้ 100%

---

## ⚡ การตั้งค่าสำคัญสำหรับ Android TV Box

เพื่อให้เซิร์ฟเวอร์ทำงานต่อเนื่อง 24 ชั่วโมงโดยไม่ดับ:
1. **ปิดโหมดประหยัดพลังงาน:**  
   เข้าไปที่ `Settings (การตั้งค่า)` -> `Apps (แอป)` -> `Termux` -> `Battery (แบตเตอรี่)` -> เลือกเป็น **Unrestricted (ไม่จำกัด)**
2. **เปิดเครื่องแล้วเซิร์ฟเวอร์รันเองอัตโนมัติ (Auto-Boot):**  
   - ติดตั้งแอปเสริม [Termux:Boot (F-Droid)](https://f-droid.org/packages/com.termux.boot/)
   - เปิดแอป Termux:Boot 1 ครั้งเพื่ออนุญาตสิทธิ์
   - ตัวติดตั้ง MumbleBox ได้เพิ่มสคริปต์ไว้ที่ `~/.termux/boot/start-mumblebox.sh` ให้เรียบร้อยแล้ว เมื่อเปิดกล่อง เซิร์ฟเวอร์จะรันเองทันที

---

## 🗑️ การถอนการติดตั้ง (Uninstall)

หากต้องการลบระบบ MumbleBox ออกทั้งหมด:
```bash
cd mumblebox
bash uninstall.sh
```
สคริปต์จะถามว่าต้องการเก็บไฟล์ Database/ประวัติห้องไว้หรือไม่ และลบการตั้งค่าเบื้องหลังให้อย่างสะอาดหมดจด

---

## 📄 License
MIT License © 2026 MumbleBox Project.

