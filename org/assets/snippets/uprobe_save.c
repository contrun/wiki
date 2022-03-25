#include "uprobe.skel.h"
#include <stdio.h>

void writeBpfObjectToFile(char filename[80]) {
  FILE *fp = fopen(filename, "wb");
  size_t size = 0;
  const void *p = uprobe_bpf__elf_bytes(&size);
  int r = fwrite(p, 1, size, fp);
  fclose(fp);
}

int main(int argc, char **argv) {
  writeBpfObjectToFile(argv[1]);
  return 0;
}
