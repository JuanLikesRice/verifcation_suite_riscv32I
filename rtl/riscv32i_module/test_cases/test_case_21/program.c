// m_ext_tests.c
#define PERIPHERAL_SUCCESS 0x00002600
#define PERIPHERAL_BYTE    0x00002604

static inline void write_mmio(unsigned int a, unsigned int v){ *(volatile unsigned int*)a = v; }
static inline void fail(int i){ write_mmio(PERIPHERAL_BYTE,i); write_mmio(PERIPHERAL_SUCCESS,0xBADF00D); for(;;); }

static inline unsigned int do_mul  (unsigned int a,unsigned int b){ unsigned int r; __asm__ volatile("mul    %0,%1,%2":"=r"(r):"r"(a),"r"(b)); return r; }
static inline unsigned int do_mulh (int a,int b){                   unsigned int r; __asm__ volatile("mulh   %0,%1,%2":"=r"(r):"r"(a),"r"(b)); return r; }
static inline unsigned int do_mulhu(unsigned int a,unsigned int b){ unsigned int r; __asm__ volatile("mulhu  %0,%1,%2":"=r"(r):"r"(a),"r"(b)); return r; }
static inline unsigned int do_mulhsu(int a,unsigned int b){         unsigned int r; __asm__ volatile("mulhsu %0,%1,%2":"=r"(r):"r"(a),"r"(b)); return r; }

int main(void){
  volatile unsigned int ua = 0x12345678u, ub = 0x9ABCDEF0u;
  volatile int sc = 0x70000000, sd = 0x70000000;
  volatile unsigned int ue = 0x76543210u, uf = 0xFEDCBA98u;
  volatile int sm1 = -1; volatile unsigned int u8000 = 0x80000000u;

  if (do_mul  (ua,ub) != 0x242D2080u) fail(1);
  if (do_mulh (sc,sd) != 0x31000000u) fail(2);
  if (do_mulhu(uf,ue) != 0x75CD9046u) fail(3);
//   if (do_mulhsu(sm1,u8000) != 0xFFFFFFFFu) fail(4);

  write_mmio(PERIPHERAL_SUCCESS, 0xDEADBEEF);
  for(;;);
}
