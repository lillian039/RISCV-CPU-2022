# RISC-V Tomasulo CPU Simulatior 🧐

#### 目录：

[TOC]

## PART0 大致框架

### CPU初步架构图：

![638ab07256c710c87647b9e7305b3b2.jpg](https://github.com/lillian039/RISCV-CPU-2022/blob/main/README.assets/638ab07256c710c87647b9e7305b3b2.jpg?raw=true)

### 所需模块

- Register
- Reorder_Buffer
- Reservation_station
- Load_store_buffer
- Instruction_queue
- Instruction_cache
- Data_cache
- ALU
- Decoder
- Branch_Target_Buffer

## PART1 Instruction Fetch

### 图示 Instruction Fetch

<img src="https://github.com/lillian039/RISCV-CPU-2022/blob/main/README.assets/997af3ed740d718f7f89832a35714ad.jpg?raw=true" alt="997af3ed740d718f7f89832a35714ad.jpg" style="zoom:33%;" />

### 所需模块：

#### （1） Icache

instruction cache，暂定大小64，由于大小较小，暂定使用 Fully Associated Cache

#### （2）Instruction Queue

pc 指针从 cache 或 RAM 中拿到的数据先放在 instruction queue 中，rob直接从 instruction queue 拿指令

#### （3）Branch Target Buffer

用于分支预测 与 ISQ、ROB 和 PC 相连 若 ISQ 拿到的指令与jump有关，就放进 BTB 判

跳就更新为 target PC，否则 PC+=4