#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/param.h"

//开启一个新进程运行命令
void run(char *cmd, char **argv)
{
    if(fork() == 0) {
        exec(cmd, argv);
        exit(0);
    }
    return;
}

int main(int argc, char *argv[])
{
    int num = 0;
    int i = 1;
    if(strcmp(argv[1], "-n") == 0)
    {
        num = atoi(argv[2]);
        // assert(num > 0);
        if(num <= 0)
        {
            printf("Usage: xargs -n  num > 0\n");
            exit(1);
        }
        if(argc < 4){
            printf("Usage: xargs [-n num] command [args...]\n");
            exit(1);
        }
        i = 3;
    }

    char buf[256];
    char *argbuf[MAXARG];
    char **args;
    args = argbuf;


    for(; i < argc; i++)
    {
        *args = argv[i];
        args++;
    }
    
    char ** args_bak = args;

    char *p = buf;
    char *plast = buf;
    if(num == 0){
        while(read(0, p, 1) > 0)
        {
            if(*p == '\n'|| *p == '\0'||*p == ' ')
            {
                *p = '\0';
                *args = plast;
                args++;
                plast = p+1;
            }
            p++;
        }
        *args = 0;
        // for( char ** pa = argbuf; pa<= args; pa++)
        // {
        //     printf("%s ", *pa);
        // }
        run(argbuf[0], argbuf);
    }else{
        int n = 0;
        while(read(0, p, 1) > 0)
        {
            if(*p == '\n' || *p == '\0' || *p == ' ')
            {
                *p = '\0';
                *args = plast;
                args++;
                plast = p+1;
                n += 1;
            }
            p++;
            if(n == num)
            {
                // for( char ** pa = argbuf; pa<= args; pa++)
                // {
                //     printf("%s ", *pa);
                // }
                *args = 0;
                run(argbuf[0], argbuf);
                wait(0);
                args = args_bak;
                n = 0;
            }
        }
        if (n > 0) {
            *args = 0; // 同样需要添加 NULL 终止符
            run(argbuf[0], argbuf);
            wait(0);
        }
    }

    while(wait(0)!= -1);
    exit(0);
}


