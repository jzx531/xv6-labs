# xv6-labs
MIT 6.S081实验代码

## 环境配置

使用wsl2 + ubuntu22.04 

```bash
 sudo apt-get install git build-essential gdb-multiarch qemu-system-misc gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu
```

卸载22.04对应的最新的qemu-system-riscv64

```bash
sudo apt-get remove qemu-system-riscv64
```

```bash
 sudo apt-get install qemu-system-misc=1:4.2-3ubuntu6
```
固定版本
```bash
sudo apt-mark hold qemu-system-misc
```

如果apt不支持对应的旧版
添加对旧版包的依赖

```bash
sudo vim /etc/apt/sources.list
```

添加

```
deb http://archive.ubuntu.com/ubuntu focal main universe
```

wq保存退出后刷新包缓存

```bash
sudo apt-get update
```

安装qemu-system-riscv64

```bash
qemu-system-riscv64 --version
QEMU emulator version 4.2.0 (Debian 1:4.2-3ubuntu6)

riscv64-unknown-elf-gcc --version
riscv64-unknown-elf-gcc () 10.2.0
```


