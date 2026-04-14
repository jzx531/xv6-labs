#include "kernel/types.h"

#include "kernel/fs.h"
#include "kernel/stat.h"
#include "user/user.h"

/*
 * 在目录 path 下递归查找文件名为 filename 的文件
 */
void find(char *path, char *filename)
{
  char buf[512], *p;      // buf 用来拼接路径，p 指向路径末尾位置
  int fd;                 // 文件描述符
  struct dirent de;       // 目录项结构（每个文件/子目录）
  struct stat st;         // 文件状态结构

  // 打开目录
  if((fd = open(path, 0)) < 0){
    fprintf(2, "ls: cannot open %s\n", path);
    return;
  }

  // 获取目录信息
  if(fstat(fd, &st) < 0){
    fprintf(2, "ls: cannot stat %s\n", path);
    close(fd);
    return;
  }

  // 如果 path 不是目录，说明用法错误
  if(st.type != T_DIR){
    fprintf(2, "usage: find <DIRECTORY> <filename>\n");
    return;
  }

  // 检查路径长度是否会溢出
  if(strlen(path) + 1 + DIRSIZ + 1 > sizeof(buf))
  {
    fprintf(2, "ls: path too long\n");
    close(fd);
    return;
  }
  
  // 先把当前路径复制到 buf
  strcpy(buf, path);

  // p 指向 buf 末尾，用于后续拼接子文件名
  p = buf + strlen(buf);

  // 在路径后加 '/'
  *p++ = '/';

  // 逐个读取目录项
  while(read(fd, &de, sizeof(de)) == sizeof(de)){
    // 空目录项跳过
    if(de.inum == 0){
      continue;
    }

    // 把目录项名字拷贝到路径后面
    memmove(p, de.name, DIRSIZ);

    // 补 '\0'，形成完整字符串
    p[DIRSIZ] = 0;

    // 获取当前路径（buf）对应文件的状态
    if (stat(buf, &st) < 0) {
        fprintf(2, "find: cannot stat %s\n", buf);
        continue;
    }

    /*
     * 如果是目录，并且不是 "." 或 ".."
     * 就递归进入子目录继续查找
     */
    if (st.type == T_DIR && strcmp(p, ".") != 0 && strcmp(p, "..") != 0) {
      find(buf, filename);
    } 
    /*
     * 如果是文件，并且名字和目标 filename 一样
     * 就打印完整路径
     */
    else if (strcmp(filename, p) == 0)
      printf("%s\n", buf);
  }

  // 关闭目录
  close(fd);
}

int main(int argc, char *argv[])
{
  // 参数检查
  if (argc != 3) {
    fprintf(2, "usage: find <directory> <filename>\n");
    exit(1);
  }

  // 从指定目录开始查找
  find(argv[1], argv[2]);

  exit(0);
}