// 编译:arm-linux-gnueabihf-gcc -static -O2 -o devmem devmem.c
// 用途:32 位板上 Python 的 os.pread 偏移量是 signed off_t,>0x7FFFFFFF 变负数
//       所以需要一个 C 工具来安全访问高地址 SLCR/AXI 寄存器
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s r|w <addr> [val]\n", argv[0]);
        return 1;
    }
    unsigned addr = strtoul(argv[2], NULL, 16);
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) { perror("open"); return 1; }
    unsigned page = addr & ~0xFFF;
    unsigned off = addr & 0xFFF;
    volatile unsigned *m = mmap(NULL, 4096, PROT_READ|PROT_WRITE,
                                MAP_SHARED, fd, page);
    if (m == MAP_FAILED) { perror("mmap"); close(fd); return 1; }
    volatile unsigned *p = (volatile unsigned *)((char *)m + off);
    if (argv[1][0] == 'r') {
        printf("0x%08x\n", *p);
    } else if (argc >= 4) {
        unsigned val = strtoul(argv[3], NULL, 16);
        *p = val;
        printf("0x%08x <= 0x%08x\n", addr, *p);
    }
    munmap((void*)m, 4096); close(fd);
    return 0;
}
