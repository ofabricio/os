#include <stdint.h>

// 0xA0000 for EGA/VGA graphics modes (64 KB)
// 0xB0000 for monochrome text mode (32 KB)
// 0xB8000 for color text mode and CGA-compatible graphics modes (32 KB)

uint16_t *video_memory = (uint16_t *)0xB8000;

void main() {
    *video_memory = 0x5050;
    return;
}
