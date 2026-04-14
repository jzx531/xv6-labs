#include "kernel/types.h"
#include "user/user.h"

#define WR 1
#define RD 0

#define INT_SIZE sizeof(int)

void transmit_lpipe2rpipe(int lpipe[2],int rpipe[2], int first)
{
    int data;
    while(read(lpipe[RD],&data,INT_SIZE) == INT_SIZE)
    {
        if(data % first)
        {
            write(rpipe[WR],&data,INT_SIZE);
        }
    }
    close(lpipe[RD]);
    close(rpipe[WR]);
}


int receivefirst_from_lpipe(int lpipe[2], int *data)
{
    if(read(lpipe[RD],data,INT_SIZE)!= INT_SIZE)
    {
        // printf("Error: read from left pipe failed\n");
        return -1;
    }
    printf("prime %d\n", *data);
    return 0;
}


void primes(int lpipe[2])
{
    close(lpipe[WR]);
    int prime;
    //每个进程筛选出一个prime数并用这个prime数进行筛选剩余数据
    if(receivefirst_from_lpipe(lpipe, &prime) == 0)
    {
        int rpipe[2];
        pipe(rpipe);
        //筛选lpipe传入rpipe中
        transmit_lpipe2rpipe(lpipe,rpipe,prime);
        
        if(fork() == 0)
        {
            primes(rpipe);
        }
        else
        {
            close(rpipe[RD]);
            wait(0);
        }
    }
    exit(0);
}

int main(int argc, char *argv[])
{
    int lpipe[2];
    pipe(lpipe);
    for(int i =2; i<=35; i++)
    {
        write(lpipe[WR],&i,INT_SIZE);
    }

    if(fork() == 0){
        primes(lpipe);
    }else{
        close(lpipe[WR]);
        close(lpipe[RD]);
        wait(0);
    }
    exit(0);
}
