#include "kernel/types.h"
// #include "kernel/stat.h"
#include "user/user.h"
#define INPUT_BUF 128
/*
父子进程同时打开读写端，能否实现双向通信？
不能，会有抢数据问题。进程被调度是无规律的，
双方都读写的话无法保证一个写进程写完数据后立即调度读进程来接收，
所以自己写的数据很可能会被自己读取
*/

int main(int argc, char *argv[]) {
    int fwcr_pipe[2];
    int cwfr_pipe[2];
    pipe(fwcr_pipe);
    pipe(cwfr_pipe);

    int pid = fork();
    if(pid < 0){
        // fork failed
        fprintf(2, "fork failed\n");
        close(fwcr_pipe[0]);
        close(fwcr_pipe[1]);
        close(cwfr_pipe[0]);
        close(cwfr_pipe[1]);
        exit(1);
    }
    else if(pid == 0)
    {
        // child process
        int exit_status = 0;
        close(fwcr_pipe[1]);//关闭父写子读管道的子写端
        close(cwfr_pipe[0]);//关闭子写父读管道的子读端
        int n = write(cwfr_pipe[1], "ping", 4*sizeof(char));
        if(n != 4*sizeof(char)){
            printf("parent write error\n");
            exit_status = 1;
        }
        close(cwfr_pipe[1]);

        // sleep(1);

        char buf[INPUT_BUF];
        n = read(fwcr_pipe[0], buf, INPUT_BUF);
        if(n != 4*sizeof(char)){
            printf("child read error\n");
            exit_status = 1;
        }else{
            int pid = getpid();
            printf("child %d received: %s\n", pid, buf);
        }
        close(fwcr_pipe[0]);
        exit(exit_status);
    }
    else
    {
        int exit_status = 0;
        // parent process
        close(fwcr_pipe[0]);//关闭父读子写管道的读端
        close(cwfr_pipe[1]);//关闭子读父写管道的写端
        char buf[INPUT_BUF];
        int n = read(cwfr_pipe[0], buf, INPUT_BUF);
        if(n != 4*sizeof(char)){
            printf("parent read error\n");
            exit_status = 1;
        }else{
            int pid = getpid();
            printf("parent %d received: %s\n", pid, buf);
        }
        close(cwfr_pipe[0]);

        // sleep(1);

        n = write(fwcr_pipe[1], "pong", 4*sizeof(char));
        if(n != 4*sizeof(char)){
            printf("parent write error\n");
            exit_status = 1;
        }
        
        close(fwcr_pipe[1]);
        wait(0);
        exit(exit_status);
    }
}