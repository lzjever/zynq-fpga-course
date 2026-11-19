#!/usr/bin/env bash
# Lab 09 主路 A:bit → bin → scp → FPGA Manager 装载(一条龙)
# 前置:FIQ 修复验收门三绿(见 README);u-boot 修复版 BOOT.BIN 已在板上
set -e
cd "$(dirname "$0")"

# ① 比特流 → PCAP 格式 .bin(字节序交换原理见 labs/bit2bin.py 注释/ch04)
python3 ../bit2bin.py lab09.runs/impl_1/axi_led_top.bit lab09.bin

# ② 送去板上固件目录(FPGA Manager 只认 /lib/firmware 里的文件名)
scp lab09.bin root@192.168.1.10:/lib/firmware/

# ③ 装载(主路 A 的两种写法,任选其一)
ssh root@192.168.1.10 'echo lab09.bin > /sys/class/fpga_manager/fpga0/firmware'
# 等价写法(你移植期的老朋友 fpgaload.ko):
#   scp lab09.bin root@192.168.1.10:/root/
#   ssh root@192.168.1.10 'insmod /root/fpgaload.ko fw=lab09.bin'

# ④ 验收:state 必须是 operating,ssh 还活着
ssh root@192.168.1.10 'cat /sys/class/fpga_manager/fpga0/state'
echo "== 三绿检查:① LED 有动静? ② 本脚本没被冻死(能走到这行)? ③ 上面打印 operating? =="
