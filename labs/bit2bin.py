#!/usr/bin/env python3
"""bit2bin.py — Xilinx .bit → Zynq devcfg(PCAP)可用 .bin
原理:剥离 .bit 文件头,定位同步字 FF FF FF FF AA 99 55 66,
之后每 32 位字做字节序交换(内核 zynq-fpga 驱动的要求,
见 drivers/fpga/zynq-fpga.c:"must be a byte swapped .bin file")
用法: python3 bit2bin.py input.bit [output.bin]
"""
import sys

bit = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else bit.rsplit('.', 1)[0] + '.bin'

data = open(bit, 'rb').read()
SYNC = bytes.fromhex('ffffffffaa995566')       # PCAP 同步字(大头序)
i = data.find(SYNC)
if i < 0:
    sys.exit("未找到同步字——这不是有效的 Xilinx .bit?")

payload = data[i:]
swapped = b''.join(payload[j:j+4][::-1] for j in range(0, len(payload), 4))
open(out, 'wb').write(swapped)
print(f"OK: {out} ({len(swapped)} 字节, 同步字 @文件偏移 {i:#x})")
