# PShell

一个内存驻留的反弹shell程序

## Usage

```
make IP=127.0.0.1 PORT=12345
```

or Debug mode

```
make debug IP=127.0.0.1 PORT=12345
```

## 基本原理

此程序启动后，由一个守护进程和一个反弹shell进程组成

守护进程会不断通过创建一个新进程并kill自己来变换PID，同时改变自身进程名称，防止被kill

同时，守护进程和反弹shell竞争同一个文件锁，当shell进程被kill掉之后，文件锁会被OS自动释放，父进程获得文件锁，检测到shell进程死亡，恢复shell进程


writed by v3rdant.