
/*
请参阅kernel/sysproc.c以获取实现sleep系统调用的xv6内核代码（查找sys_sleep），
user/user.h提供了sleep的声明以便其他程序调用，
用汇编程序编写的user/usys.S可以帮助sleep从用户区跳转到内核区。
*/
#include "kernel/types.h"
// #include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
    int n;
    if (argc != 2) {
        fprintf(2, "Usage: sleep seconds\n");
        exit(1);
    }
    n = atoi(argv[1]);
    sleep(n * 10 );
    exit(0);
}