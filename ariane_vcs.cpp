// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at

//   http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

#include <functional>
#include <time.h>
#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <string>
#include <memory>
#include <fesvr/device.h>
#include <fesvr/htif.h>
#include <fesvr/memif.h>
#include <fesvr/htif_hexwriter.h>
#include <fesvr/context.h>
#include <stdio.h>
#include <queue>
#include <fesvr/option_parser.h>
#include "svdpi.h"
#include <stdio.h>
#include <assert.h>

class simmem_t : public htif_t
{
public:
  simmem_t(int argc, char** argv, size_t b, size_t w, size_t d);
  simmem_t(const std::vector<std::string>& args, size_t b, size_t w, size_t d);

  void set_vcd (const char *vcd_file) { this->vcd_file = vcd_file; }
  int run();
  addr_t get_tohost_address();
  addr_t get_fromhost_address();

private:
  size_t base;
  size_t width;
  size_t depth;
  std::map<addr_t,std::vector<char> > mem;

  std::queue<bool> flush_req;
  std::queue<bool> flushing;

  void flush_dcache();
  const char * vcd_file;

  void read_chunk(addr_t taddr, size_t len, void* dst);
  void write_chunk(addr_t taddr, size_t len, const void* src);

  size_t chunk_max_size() { return 8; }
  size_t chunk_align() { return 8; }
  void reset() { }

  context_t* host;
  context_t target;

  // htif
  friend void sim_thread_main(void*);
  void main();
  void idle();

};

std::unique_ptr<simmem_t> htif;
bool stop_sim = false;

simmem_t::simmem_t(int argc, char** argv, size_t b, size_t w, size_t d)
  : htif_t(argc, argv), base(b), width(w), depth(d) {

}

simmem_t::simmem_t(const std::vector<std::string>& args, size_t b, size_t w, size_t d)
  : htif_t(args), base(b), width(w), depth(d) {

}

void sim_thread_main(void* arg) {
  ((simmem_t*)arg)->main();
}

void simmem_t::main() {

}

addr_t simmem_t::get_tohost_address() {
  return htif_t::tohost_addr;
}

addr_t simmem_t::get_fromhost_address() {
  return htif_t::fromhost_addr;
}

void simmem_t::flush_dcache() {
  flush_req.push(true);
}

void simmem_t::idle()
{
  target.switch_to();
}

int simmem_t::run()
{
  host = context_t::current();
  target.init(sim_thread_main, this);
  return htif_t::run();
}

void simmem_t::read_chunk(addr_t taddr, size_t len, void* vdst)
{
  taddr -= base;

  assert(len % chunk_align() == 0);
  if (taddr >= width*depth) {
    return;
  }

  uint8_t* dst = (uint8_t*)vdst;
  while(len)
  {
    if(mem[taddr/width].size() == 0)
      mem[taddr/width].resize(width,0);

    for(size_t j = 0; j < width; j++)
      dst[j] = mem[taddr/width][j];

    len -= width;
    taddr += width;
    dst += width;
  }
}

void simmem_t::write_chunk(addr_t taddr, size_t len, const void* vsrc)
{
  if (taddr == fromhost_addr) {
    flush_dcache();
  }

  taddr -= base;

  assert(len % chunk_align() == 0);
  if (taddr >= width*depth) {
    return;
  }

  const uint8_t* src = (const uint8_t*)vsrc;
  while(len)
  {
    if(mem[taddr/width].size() == 0)
      mem[taddr/width].resize(width,0);

    for(size_t j = 0; j < width; j++)
      mem[taddr/width][j] = src[j];

    len -= width;
    taddr += width;
  }
}

extern unsigned long long read_uint64 (unsigned long long address) {

  // as we do not have physical memory protection at the moment check here for invalid accesses
  // in the soc this is done by the AXI bus
  if (address < 0x80000000) {
    return 0xdeadbeafdeadbeef;
  }

  return htif->memif().read_uint64(address);
}

extern void write_uint64 (unsigned long long address, unsigned long long data) {
  htif->memif().write_uint64(address, data);
}

extern unsigned long long get_tohost_address() {
  return htif->get_tohost_address();
}

extern unsigned long long get_fromhost_address() {
  return htif->get_fromhost_address();
}

static void help()
{
  fprintf(stderr, "usage: ariane C verilator simulator [host options] <target program> [target options]\n");
  exit(1);
}

int main(int argc, char **argv) {

  const char* vcd_file = NULL;
  bool dump_perf = false;

  option_parser_t parser;
  parser.help(&help);
  parser.option('h', 0, 0, [&](const char* s){help();});
  parser.option(0, "vcd", 1, [&](const char* s){vcd_file = s;});

  auto argv1 = parser.parse(argv);
  std::vector<std::string> htif_args(argv1, (const char*const*)argv + argc);

  htif.reset(new simmem_t(htif_args, 0x80000000, 8, 2097152));

  htif->set_vcd(vcd_file);
  htif->start();

  clock_t t;
  t = clock();

  htif->run();

  t = clock() - t;
  exit(0);
}
