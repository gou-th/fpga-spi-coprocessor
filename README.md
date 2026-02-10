## Project Overview

This project implements a hardware-accelerated **Arithmetic Logic Unit (ALU)** on a **Xilinx Artix-7 FPGA (Basys 3)**, interfaced with an **ESP32 microcontroller** over a standard **SPI interface**.

The system demonstrates **hardware–software co-design**, where computationally intensive operations—specifically **Multiply-Accumulate (MAC)** functions commonly used in signal processing, are offloaded from the microcontroller to a FPGA-based compute engine.

While modern microcontrollers offer high clock speeds, they suffer from interrupt latency and execution jitter. The FPGA implementation provides a low-latency computation, making it significantly better suited for real-time workloads. The design incorporates proper **Clock Domain Crossing (CDC)** techniques to ensure reliable data transfer between the 100 MHz FPGA clock domain and the asynchronous SPI bus.

---

## System Architecture

The system is composed of four primary SystemVerilog modules:

1. [`spi_receiver.sv`](./rtl/spi_receiver.sv)
   Deserializes MOSI data using triple flip-flop synchronizers to mitigate metastability.

2. [`alu.sv`](./rtl/alu.sv)
   A 32-bit arithmetic core featuring a persistent accumulator supporting MAC operations along with basic arithmetic functions.

3. [`spi_transmitter.sv`](./rtl/spi_transmitter.sv)
   Serializes computation results onto MISO, incorporating edge-detection logic to prevent bit-shift errors.

4. [`top.sv`](./rtl/top.sv)
   Top-level module managing control flow, handshaking and single-cycle load pulses.

---

## Instruction Set Architecture (ISA)

The system accepts fixed 24-bit SPI packets structured as:

`[ Opcode (8 bits) | Operand A (8 bits) | Operand B (8 bits) ]`

| Opcode | Mnemonic | Operation        | Description             |
| :----: | :------: | :--------------- | :---------------------- |
| `0x01` |    ADD   | `A + B`          | Unsigned addition       |
| `0x02` |    MUL   | `A * B`          | Unsigned multiplication |
| `0x05` |    MAC   | `Acc += (A * B)` | Multiply-Accumulate     |
| `0x06` |    CLR   | `Acc = 0`        | Clear accumulator       |
| `0x07` |  RD_ACC  | `MISO = Acc`     | Read accumulator value  |
| `0x08` |  RD_LAST | `MISO = Result`  | Read last computation   |

---

## Hardware Setup

**FPGA Board:** Digilent Basys 3 (Artix-70
**SPI Interface:** PMOD Header JA (Top row)

| Signal | Basys 3 Pin | PMOD Pin | ESP32 GPIO |
| :----- | :---------- | :------- | :--------- |
| SCK    | J1          | Pin 1    | GPIO 18    |
| MOSI   | L2          | Pin 2    | GPIO 23    |
| MISO   | J2          | Pin 3    | GPIO 19    |
| CS     | G2          | Pin 4    | GPIO 5     |
| GND    | GND         | Pin 5    | GND        |

---

## Simulation Verification

A SystemVerilog testbench [`tb_spi_coprocessor.sv`](./sim/tb_spi_coprocessor.sv) was developed to validate:

* Functional correctness of all supported opcodes
* Timing and alignment of the SPI shift register

---

## Hardware Verification

The generated bitstream was deployed onto the Basys 3 FPGA. Functional verification was performed using the onboard LEDs and ESP32 serial output.

**Verification Results:**

* Case 1: LED output `0010 1010` (decimal 42)
* Case 2: LED output `0011 0110` (decimal 54)

The system maintained data integrity during sustained operation at a **1 MHz SPI clock**, confirming correct CDC implementation and stable cross-domain communication.

---

## How to Run

### FPGA Setup (Vivado)

1. Create a new Vivado project targeting **XC7A35T-1CPG236C**.
2. Add all `.sv` files from the `hdl/` directory.
3. Add `basys3_master.xdc` from the [`constraints`](./constraints) directory.
4. Generate the bitstream and program the board using Hardware Manager.

### Software Setup (Arduino IDE)

1. Install the ESP32 board package.
2. Open [`software/esp32_master.ino`](./software/esp32_master.ino).
3. Select the appropriate board and port, then upload.
4. Open the Serial Monitor at **115200 baud**.

### Folder Structure 

spi-fpga-alu/
├── hdl/
│   ├── spi_receiver.sv        # SPI MOSI deserializer with CDC handling
│   ├── alu.sv                 # 32-bit ALU with MAC accumulator
│   ├── spi_transmitter.sv     # SPI MISO serializer
│   └── top.sv                 # Top-level integration module
├── tb/
│   └── tb_spi_coprocessor.sv  # Self-checking SystemVerilog testbench
├── constraints/
│   └── basys3_master.xdc      # FPGA pin constraints
├── software/
│   └── esp32_master.ino       # ESP32 SPI master firmware
├── docs/
│   └── verification.md        # Linked waveforms and hardware verification notes
└── README.md
