# GarlicOS: Nintendo DS

Academic project for **Operating System Architecture 2025-26**.

GarlicOS is a layered micro-kernel capable of running up to **16 concurrent processes** on Nintendo DS hardware, implementing a strict API-call boundary between user space and kernel space.

---

## 📺 Demo Video

https://github.com/user-attachments/assets/76a9cab3-cbea-4b7e-9934-82f4e20827dc

---

## Project Overview

The system is built on a modular architecture where each core component was developed with a specific focus on hardware optimization:

* **ProgP (Process Handling):** Managed concurrency and process scheduling using only **ARM Assembly**.
* **ProgM (Memory Management):** Implemented memory allocation, protection, and `.elf` executable loading (C & ARM).
* **ProgG (Graphics Engine):** Developed the graphical interface, managing **VRAM**, hardware sprites, and real-time **rotation/scaling** (C & ARM).

---
*For more details, check the [manuals](./docs).*

