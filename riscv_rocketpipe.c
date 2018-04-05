#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <inttypes.h>
#include <assert.h>
#include <stdbool.h>
#include <fenv.h>
#include <math.h>
#ifdef __APPLE__
#include <float.h>     // For Mac OS X
#else
#include <values.h>    // For Linux
#endif

#include "../vc_hdrs.h"
#include "l3riscv.h"
#include "riscv_ffi.h"

static int lib_is_opened = 0;
static int log_opened = 0;

const char *dummy_argv[] = {
  "libl3riscv.so",
  "-v",
  "true",
  "-b",
  "false",
  "-t",
  "0",
  NULL
};

#define DECLARE_INSN(nam, match, mask) op_##nam,
typedef enum {
#include "encoding.h"
} opcode_t;
#undef DECLARE_INSN

typedef struct {
  opcode_t op;
  const char *nam;
  uint32_t match, mask;
} encoding_t;

#define DECLARE_INSN(nam, match, mask) {op_##nam, #nam, match, mask},
encoding_t encodings[] = {
#include "encoding.h"
};
#undef DECLARE_INSN

typedef struct {
  uint64_t hartid, time, valid, iaddr, w_reg, rf_wdata, rf_wen, rs1, rs1_rdata, rs2, rs2_rdata, insn0;
  encoding_t *found;
} commit_t;

enum {lenmax=1<<20};

#define DECLARE_FMT(nam) fmt_##nam,
typedef enum {
#include "format.h"
} fmt_t;
#undef DECLARE_FMT

#define DECLARE_FMT(nam) #nam,
const char *fmtnam[] = {
#include "format.h"
};
#undef DECLARE_FMT

static int head = 0;
static int tail = 0;
static int lencrnt = 0;
static int terminating = 0;
static int notified = 0;
static commit_t *instrns;
static uint64_t cycles, commit_cycles = 999999;
static uint64_t regs[32];
static uint64_t csr_table[4095];
static fmt_t get_fmt(opcode_t op)
{
  fmt_t fmt = fmt_unknown;
  switch(op)
    {
    case op_mul:
    case op_mulh:
    case op_mulhu:
    case op_mulhsu:
    case op_mulw:
    case op_div:
    case op_divu:
    case op_divuw:
    case op_divw:
    case op_rem:
    case op_remu:
    case op_remuw:
    case op_remw:
      fmt = fmt_R;
      break;
    case op_jal:
    case op_jalr:
      fmt = fmt_UJ;
      break;
    case op_uret:
    case op_sret:
    case op_mret:
    case op_fence:
      fmt = fmt_PRIV;
      break;
    case op_beq:
    case op_bne:
    case op_blt:
    case op_bge:
    case op_bltu:
    case op_bgeu:
      fmt = fmt_SB;
      break;
    case op_csrrc:
    case op_csrrci:
    case op_csrrw:
    case op_csrrs:
      fmt = fmt_I;
      break;
    case op_csrrwi:
      fmt = fmt_I;
      break;
    case op_ecall:
      fmt = fmt_I;
      break;
    case op_sb:
    case op_sd:
    case op_sh:
    case op_sw:
      fmt = fmt_S;
      break;
    case op_lb:
    case op_lbu:
    case op_ld:
    case op_lh:
    case op_lhu:
    case op_lw:
    case op_lwu:
      fmt = fmt_I;
      break;
    case op_add:
    case op_addw:
    case op_sub:
    case op_subw:
    case op_slt:
    case op_sltu:
    case op_and:
    case op_or:
    case op_xor:
    case op_sll:
    case op_srl:
    case op_sra:
      fmt = fmt_R;
      break;
    case op_addi:
    case op_addiw:
    case op_andi:
    case op_slti:
    case op_sltiu:
    case op_ori:
    case op_xori:
    case op_slli:
    case op_slliw:
    case op_srli:
    case op_srliw:
    case op_srai:
      fmt = fmt_I;
      break;
    case op_lui:
    case op_auipc:
      fmt = fmt_U;
      break;
    case op_fence_i:
    case op_sfence_vma:
      fmt = fmt_PRIV;
      break;
    default:
      fprintf(stderr, "Unhandled instruction %s at line %d\n", encodings[op].nam, __LINE__);
      abort();
    }
  return fmt;
}

static encoding_t *find(uint64_t insn0)
{
  int j;
  encoding_t *found = NULL;
  for (j = 0; j < sizeof(encodings)/sizeof(*encodings); j++)
    {
      if ((insn0 & encodings[j].mask) == encodings[j].match)
        found = encodings+j;
    }
  return found;
}

static uint64_t lookahead(int offset, int reg)
{
  int i = offset;
  fmt_t fmt;
  printf("**LOOKAHEAD reg(%d)\n", reg);
  while (i < tail)
    {
      fmt = get_fmt(instrns[i].found->op);
      switch(fmt)
        {
        case fmt_R:
        case fmt_S:
        case fmt_SB:
          if (instrns[i].rs2 == reg) return instrns[i].rs2_rdata;
        case fmt_I:
          if (instrns[i].rs1 == reg) return instrns[i].rs1_rdata;
        case fmt_U:
        case fmt_UJ:
          break;
        default:
          fprintf(stderr, "Invalid format %d at line %d\n", fmt, __LINE__);
          abort();
        }
      switch(fmt)
        {
        case fmt_S:
        case fmt_SB:
          break;
        case fmt_I:
        case fmt_R:
        case fmt_U:
        case fmt_UJ:
          if (instrns[i].w_reg == reg) return regs[reg]; // This default may or may not make sense
          break;
        default:
          fprintf(stderr, "Invalid format %d at line %d\n", fmt, __LINE__);
          abort();
        }
      ++i;
    }
  return regs[reg];
}

static const char *stem;
static int checking = 0;
static int exit_pending = 0;
static FILE *fd;
static uint64_t start = 0;
static uint64_t tohost = 0;

void interp_log(commit_t *ptr)
{
  int j;
  uint64_t cpu = 0;
  uint32_t cmd = 0;
  uint32_t exc_taken = 0;
  uint64_t pc = 0;
  uint64_t addr = 0;
  uint64_t data1 = 0;
  uint64_t data2 = 0;
  uint64_t data3 = 0;
  uint64_t fpdata = 0;
  uint32_t verbosity = 0;
  uint32_t rslt = 0;
  int reg1 = 0, reg2 = 0, rd = 0;
  fmt_t fmt = get_fmt(ptr->found->op);
  int32_t imm = (int32_t)(ptr->insn0) >> 20;
  switch(fmt)
    {
    case fmt_S:
    case fmt_SB:
      imm = (imm & -32) | ((ptr->insn0 >> 7)&31);
    case fmt_R:
      reg2 = (ptr->insn0 >> 20)&31;
    case fmt_I:
    case fmt_PRIV:
      reg1 = (ptr->insn0 >> 15)&31;
    case fmt_U:
    case fmt_UJ:
      rd = (ptr->insn0 >> 7)&31;
      break;
    default:
      fprintf(stderr, "Invalid format %d for instruction %s at line %d\n", fmt, ptr->found->nam, __LINE__);
      abort();
    }
  printf("**DISASS[%ld]:%s(%s) ", ptr->time, ptr->found->nam, fmtnam[fmt]);
  if (rd) printf("rd=%d[%lx] ", rd, ptr->rf_wdata);
  if (reg1) printf("r1=%d[%lx] ", reg1, regs[reg1]);
  if (reg2) printf("r2=%d[%lx] ", reg2, regs[reg2]);
  if (imm && (fmt==fmt_S)) printf("@(%x) ", imm);
  printf("\n");
  cpu = ptr->hartid;
  cmd = 0;
  exc_taken = 0;
  pc = ptr->iaddr;
  data1 = ptr->rf_wdata;
  data2 = ptr->rs1_rdata;
  data3 = ptr->insn0;
  fpdata = 0;
  verbosity = 0;
  addr = ptr->iaddr+4;
  switch(ptr->found->op)
    {
    case op_mul:
      data1 = ptr->rf_wdata;
      break;
    case op_mulh:
    case op_mulhu:
    case op_mulhsu:
    case op_mulw:
    case op_div:
    case op_divu:
    case op_divuw:
    case op_divw:
    case op_rem:
    case op_remu:
    case op_remuw:
    case op_remw:
      if (ptr+1 >= instrns+tail) return;
      data1 = ptr[1].rf_wdata;
      break;
    case op_jal:
      addr = ptr->insn0 >> 12;
      addr = ptr->iaddr + ((((addr >> 9)&1023)<<1) | (((addr >> 8)&1)<<11) | ((addr&255)<<12) | ((addr >> 19)&1 ? (-1<<20) : 0));
      data1 = ptr->rf_wdata;
      break;
    case op_jalr:
    case op_beq:
    case op_bne:
    case op_blt:
    case op_bge:
    case op_bltu:
    case op_bgeu:
      if (ptr+1 >= instrns+tail) return;
      addr = ptr[1].iaddr;
      data1 = ptr->rf_wdata;
      break;
    case op_uret:
    case op_sret:
    case op_mret:
      addr = ptr->rf_wdata;
      break;
    case op_csrrw:
    case op_csrrs:
    case op_csrrwi:
      addr = imm;
      data1 = csr_table[imm];
      if (ptr->w_reg == reg1)
        data2 = ptr->rs1_rdata;
      else
        data2 = regs[reg1];
      csr_table[imm] = regs[reg1];
      switch(addr)
        {
        case CSR_MISA:
        case 0xf10:
          data1 = (ptr->rf_wdata | (1<<20)) & ~0xFF;
          printf("**TRACE:MISA=%lx\n", data1);
          fflush(stdout);
          break;
        case CSR_STVEC:
          data1 = 0x0;
          break;
        case CSR_MTVEC:
          printf("CSR_MTVEC: %lX, %lX, %lX\n", addr, data1, data2);
          break;
        case CSR_MSTATUS:
          data1 = 0x2000;
          data2 |= 0x2000;
          break;
        case CSR_MEPC:
          data1 = 0x0;
          break;
        default:
          data1 = ptr->rf_wdata;
        }
      break;
    case op_ecall:
      if (ptr+1 >= instrns+tail) return;
      addr = ptr[1].iaddr;
      data1 = ptr->rf_wdata;
      exc_taken = 1;
      break;
    case op_sb:
    case op_sd:
    case op_sh:
    case op_sw:
      data1 = ptr->rs1_rdata;
      data2 = regs[reg2];
      addr = regs[reg1] + imm;
      if (addr == tohost)
        {
          if (!exit_pending++)
            fprintf(stderr, "Exit is pending after tohost access\n");
        }
      break;
    case op_lb:
    case op_lbu:
    case op_ld:
    case op_lh:
    case op_lhu:
    case op_lw:
    case op_lwu:
      printf("**LOAD reg(%d), addr1=%lX, addr2=%lX, addr3=%lX, imm=%d, w_reg=%x\n", reg1, ptr->rs1_rdata, regs[reg1]+imm, ptr->rf_wdata, imm, ptr->w_reg);
      if ((ptr->w_reg == reg1) && ptr->rf_wdata)
        {
        addr = ptr->rs1_rdata + imm;
        data1 = ptr->rf_wdata;
        }
      else if (ptr->w_reg == rd)
        {
        addr = regs[reg1] + imm;
        data1 = ptr->rf_wdata;
        }
      else
        {
        addr = regs[reg1] + imm;
        data1 = lookahead(ptr-instrns+1, rd);
        }
      break;
    default:
      break;
    }
  // It looks like we have the information needed, so submit this instruction and update regs
  if ((ptr->w_reg > 0) && (ptr->w_reg < 32))
    regs[ptr->w_reg] = ptr->rf_wdata;
  ++head;
  for (j = 0; j < (ptr->found->op == op_auipc && ptr->iaddr == start ? 2 : 1); j++) // hack alert
    {
      printf("**TRACE:op[%ld] => %s(%d)\n", ptr->time, ptr->found->nam, ptr->found->op);
      fflush(stdout);
      if (!terminating)
        rslt = l3riscv_verify(cpu,
                            cmd,
                            exc_taken,
                            pc,
                            addr,
                            data1,
                            data2,
                            data3,
                            fpdata,
                            verbosity);
    }
}

static void dump_log(FILE *fd, commit_t *ptr)
{
  fprintf(fd, "C%ld: %ld [%ld] pc=[%lx] W[r%ld=%lx][%ld] R[r%ld=%lx] R[r%ld=%lx] inst=[%lx] DASM(%lx) %s\n",
                    ptr->hartid, ptr->time, ptr->valid,
                    ptr->iaddr,
                    ptr->w_reg, ptr->rf_wdata, ptr->rf_wen,
                    ptr->rs1, ptr->rs1_rdata,
                    ptr->rs2, ptr->rs2_rdata,
                    ptr->insn0, ptr->insn0, ptr->found->nam);
  if (exit_pending)
    ++exit_pending;
  if (exit_pending > 5)
    {
      if (head >= tail)
        {
          fprintf(stderr, "Exit due to pending instruction stream exhausted after %d instructions\n", head);
          exit(0);
        }
    }
  else if (++tail >= lencrnt)
    {
      lencrnt *= 2;
      instrns = (commit_t *)realloc(instrns, lencrnt*sizeof(commit_t));
    }
}

static void rocketlog_main(const char *elf)
{
  char linbuf[256];
  char lognam[99];
  const char *basename = strrchr(elf, '/');
  stem = basename ? basename+1 : elf;
  sprintf(lognam, "%s_filt.log", stem);
  log_opened = 1;
  fd = freopen(lognam, "w", stdout);
  l3riscv_open(7, dummy_argv);
  
  l3riscv_mem_load_elf();
  start = l3riscv_mem_get_min_addr();
  tohost = l3riscv_mem_get_tohost_addr();
  fprintf(stderr, "Tohost address in isatest = %.016lX\n", tohost);
  lencrnt = lenmax;
  instrns = (commit_t *)malloc(lencrnt*sizeof(commit_t));
  csr_table[CSR_MISA] = 0;
  csr_table[0xf10] = 0;
  csr_table[CSR_STVEC] = 0;
  csr_table[CSR_MTVEC] = 0x100;
  csr_table[CSR_MSTATUS] = 0x2000;
  csr_table[CSR_MEPC] = 0;
}

int pipe_init(const char* s)
{
  char *basename, path[256], env[256];
  int len = readlink(s, path, sizeof(path));
  if (len < 0)
    {
      strcpy(path, s);
    }
  else
    {
    path[len] = 0;
    }
  basename = strstr(path, ".hex");
  if (basename)
    {
      *basename = 0;
      printf("Checking %s...\n", path);
      if (access(path, R_OK) == 0)
        {
          sprintf(env, "SIM_ELF_FILENAME=%s", path);
          putenv(env);
          rocketlog_main(path);
        }
      else
        perror(path);
    }
  else
    fprintf(stderr, "+readmemh=arg should end in .hex\n");
}

int pipe27(long long arg1, long long arg2, long long arg3, long long arg4, long long arg5,
                     long long arg6, long long arg7, long long arg8, long long arg9, long long arg10, 
                     long long arg11, long long arg12, long long arg13, long long arg14, long long arg15,
                     long long arg16, long long arg17, long long arg18, long long arg19, long long arg20, 
                     long long arg21, long long arg22, long long arg23, long long arg24, long long arg25,
                     long long arg26, long long arg27)
{
  commit_t *ptr = instrns+tail;
  uint64_t commit_instr_id_commit_ex_cause;
  uint64_t flush_unissued_instr_ctrl_id;
  uint64_t flush_ctrl_ex;
  uint64_t id_stage_i_compressed_decoder_i_instr_o;
  uint64_t id_stage_i_instr_realigner_i_fetch_entry_valid_o;
  uint64_t id_stage_i_instr_realigner_i_fetch_ack_i;
  uint64_t issue_stage_i_scoreboard_i_issue_ack_i;
  uint64_t waddr_a_commit_id;
  uint64_t wdata_a_commit_id;
  uint64_t we_a_commit_id;
  uint64_t commit_ack;
  uint64_t ex_stage_i_lsu_i_i_store_unit_store_buffer_i_valid_i;
  uint64_t ex_stage_i_lsu_i_i_store_unit_store_buffer_i_paddr_i;
  uint64_t ex_stage_i_lsu_i_i_load_unit_tag_valid_o;
  uint64_t ex_stage_i_lsu_i_i_load_unit_kill_req_o;
  uint64_t ex_stage_i_lsu_i_i_load_unit_paddr_i;
  uint64_t commit_instr_ex_tval;
  uint64_t exception_valid;
  uint64_t priv_lvl;
  if (!arg1)
    cycles = 0;
  else if (log_opened)
    {
      if (arg2)
        {
          //          if (!terminating)
            commit_cycles = cycles;
          (ptr->time) = cycles;
          (ptr->iaddr) = arg3;
          (ptr->insn0) = arg4;
          exception_valid = arg5;
          commit_instr_id_commit_ex_cause = arg6;
          flush_unissued_instr_ctrl_id = arg7;
          flush_ctrl_ex = arg8;
          id_stage_i_compressed_decoder_i_instr_o = arg9;
          id_stage_i_instr_realigner_i_fetch_entry_valid_o = arg10;
          id_stage_i_instr_realigner_i_fetch_ack_i = arg11;
          issue_stage_i_scoreboard_i_issue_ack_i = arg12;
          waddr_a_commit_id = arg13;
          wdata_a_commit_id = arg14;
          we_a_commit_id = arg15;
          commit_ack = arg16;
          ex_stage_i_lsu_i_i_store_unit_store_buffer_i_valid_i = arg17;
          ex_stage_i_lsu_i_i_load_unit_tag_valid_o = arg18;
          ex_stage_i_lsu_i_i_load_unit_kill_req_o = arg19;
          ex_stage_i_lsu_i_i_load_unit_paddr_i = arg20;
          priv_lvl = arg21;
          (ptr->rs1) = arg22;
          (ptr->rs1_rdata) = arg23;
          (ptr->rs2) = arg24;
          (ptr->rs2_rdata) = arg25;
          (ptr->w_reg) = arg26;
          (ptr->rf_wdata) = arg27;
          if (exception_valid)
            {
              uint32_t rslt = 0;
              while (head != tail)
                interp_log(instrns+head);

              switch(commit_instr_id_commit_ex_cause)
                {
                case CAUSE_MISALIGNED_FETCH:    printf("CAUSE_MISALIGNED_FETCH\n"); break;
                case CAUSE_FETCH_ACCESS:        printf("CAUSE_FETCH_ACCESS\n"); break;
                case CAUSE_ILLEGAL_INSTRUCTION: printf("CAUSE_ILLEGAL_INSTRUCTION\n"); break;
                case CAUSE_BREAKPOINT:          printf("CAUSE_BREAKPOINT\n"); break;
                case CAUSE_MISALIGNED_LOAD:     printf("CAUSE_MISALIGNED_LOAD\n"); break;
                case CAUSE_LOAD_ACCESS:         printf("CAUSE_LOAD_ACCESS\n"); break;
                case CAUSE_MISALIGNED_STORE:    printf("CAUSE_MISALIGNED_STORE\n"); break;
                case CAUSE_STORE_ACCESS:        printf("CAUSE_STORE_ACCESS\n"); break;
                case CAUSE_USER_ECALL:          printf("CAUSE_USER_ECALL\n"); break;
                case CAUSE_SUPERVISOR_ECALL:    printf("CAUSE_SUPERVISOR_ECALL\n"); break;
                case CAUSE_HYPERVISOR_ECALL:    printf("CAUSE_HYPERVISOR_ECALL\n"); break;
                case CAUSE_MACHINE_ECALL:       printf("CAUSE_MACHINE_ECALL\n"); break;
                case CAUSE_FETCH_PAGE_FAULT:    printf("CAUSE_FETCH_PAGE_FAULT\n"); break;
                case CAUSE_LOAD_PAGE_FAULT:     printf("CAUSE_LOAD_PAGE_FAULT\n"); break;
                case CAUSE_STORE_PAGE_FAULT:    printf("CAUSE_STORE_PAGE_FAULT\n"); break;
                default:                        printf("**Exception cause %lX\n", commit_instr_id_commit_ex_cause);
                }
              fflush(stdout);
#if 1
              rslt = l3riscv_verify(ptr->hartid,
                            0,
                            1,
                            ptr->iaddr,
                            0,
                            0,
                            commit_instr_id_commit_ex_cause,
                            0,
                            0,
                            0);
#else
              terminating = 1;
#endif              
            }
          else
            {
              if (!ptr->insn0)
                {
                  fprintf(stderr, "Internal error, the instruction logged was 0\n");
                  abort();
                }
              ptr->found = find(ptr->insn0);
              ptr->valid = 1;
              checking = 1;
              if (checking && ptr->found)
                {
                dump_log(fd, ptr);
                interp_log(instrns+head);
                }
            }
        }
      if (++cycles > commit_cycles+1000000)
        {
          if (!notified)
            {
              notified = 1;
              fprintf(stderr, "Cycle count reached %ld with no further commits\n", cycles);
              l3riscv_done();
              exit(0);
            }
        }
    }
}

#if 0
void l3_finish(void)
{
  fprintf(stderr, "%s: Normal end of execution logfile\n", stem);
  l3riscv_done();
}
#endif
