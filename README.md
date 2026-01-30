# FPGA SPI Coprocessor (MAC & CDC)

![Status](https://img.shields.io/badge/Status-Verified_in_Simulation-success)
![Hardware](https://img.shields.io/badge/Hardware-Basys3_%2B_ESP32-blue)
![Language](https://img.shields.io/badge/Language-SystemVerilog-orange)

## Project Overview
This project implements a hardware-accelerated **Arithmetic Logic Unit (ALU)** on a Xilinx Artix-7 FPGA (Basys 3). It communicates with an ESP32 microcontroller via a standard **SPI Interface**.

The core logic offloads computationally intensive tasks—specifically **Multiply-Accumulate (MAC)** operations used in Signal Processing—from the microcontroller to the FPGA. The design features **Clock Domain Crossing (CDC)** to ensure reliable data transfer between the 100MHz FPGA clock and the asynchronous SPI bus.

To justify the use of an FPGA, while modern microcontrollers have fast CPUs, they suffer from interrupt latency and jitter. The FPGA implementation offers very low latency, making it way faster for real-time computations.

## System Architecture
The system consists of four main SystemVerilog modules:
1.  **`spi_receiver.sv`**: Deserializes MOSI data using Triple Flip Flop Synchronizers to prevent metastability.
2.  **`alu.sv`**: A 32-bit Math Core with a persistent Accumulator (MAC unit) along with other basic operations.
3.  **`spi_transmitter.sv`**: Serializes results to MISO, featuring edge detection mechanism to prevent bit-shift errors.
4.  **`top.sv`**: Manages the handshake signals and single-cycle load pulses.

## Instruction Set (ISA)
The system accepts 24-bit packets: `[Opcode (8)] [Operand A (8)] [Operand B (8)]`

| OpCode | Mnemonic | Operation | Description |
| :--- | :--- | :--- | :--- |
| `0x01` | **ADD** | `A + B` | Basic Addition |
| `0x02` | **MUL** | `A * B` | Unsigned Multiplication |
| `0x05` | **MAC** | `Acc += (A * B)` | **Multiply-Accumulate** (MAC) |
| `0x06` | **CLR** | `Acc = 0` | Clear Accumulator |
| `0x07` | **RD_ACC** | `MISO = Acc` | Read Accumulator Value |
| `0x08` | **RD_LAST**| `MISO = Result` | Read Last Calculation |

## Hardware Setup
**Board:** Digilent Basys 3 (Artix-7 XC7A35T)
**Port:** PMOD Header JA (Top Row)

| Signal | Basys 3 Pin | PMOD Pin | ESP32 Pin |
| :--- | :--- | :--- | :--- |
| **SCK** | `J1` | Pin 1 | GPIO 18 |
| **MOSI** | `L2` | Pin 2 | GPIO 23 |
| **MISO** | `J2` | Pin 3 | GPIO 19 |
| **CS** | `G2` | Pin 4 | GPIO 5 |
| **GND** | `GND` | Pin 5 | GND |

## Verification
The design includes a self-checking testbench (`tb_spi_coprocessor.sv`) that validates:
* 100% of Opcodes.
* Timing of the SPI Shift Register.

## How to Run
1.  **FPGA:** Open the `hdl/` files in Vivado, add the `basys3_master.xdc` constraint and generate the bitstream.
2.  **ESP32:** Flash the `esp32_master.ino` code to your microcontroller.
3.  **Connect:** Wire the PMOD JA pins to the ESP32.
4.  **Test:** Open the Serial Monitor (115200 baud) to see the math results.
