#!/bin/bash

XRDHOST=cmssrv152.fnal.gov
echo -n "-> Setting working directory: "
if [ "a$1" == "a" ] ; then 
  workdir=/eos/uscms/store/user/catalind/test123/
else 
  workdir="$1"
fi 
mkdir -p $workdir && cd $workdir || exit
echo passed
ls -ald $workdir 

usr=`whoami`


a=passed
echo ">>> Basic operations: mkdir, rmdir, cp(dir), mv(dir)"
mkdir test123 && ls -ald test123 | grep $usr && echo "-> mkdir: passed" || echo "-> mkdir: failed"
rmdir test123 && ls -ald test123 2>&1 | grep $usr && echo "-> rmdir: failed" || echo "-> rmdir: passed"
mkdir test123 
cp -r test123 test1234 && ls -ald test1234 | grep $usr && echo "-> cpdir: passed" || echo "-> cpdir: failed"
mv test1234 test12345 && ls -ald test12345 | grep $usr && echo "-> mvdir: passed" || echo "-> mvdir: failed"
rmdir test123 test12345

echo ">>> Basic file operations: > (date > testfile123 ; date >> testfile123)"
date > testfile123 && cat testfile123
ls -al testfile123 | grep $usr 
date >> testfile123 && cat testfile123
cat testfile123 | wc -l | grep 2 && echo "-> concat operations: passed" || echo "-> concat operations: failed"

echo ">>> Basic file operations: mv, cp (mv testfile123 testfile1234 && cp testfile1234 testfile12345)"
mv testfile123 testfile1234 && cp testfile1234 testfile12345
ls -al testfile123 testfile1234 testfile12345 2>&1
echo "Moved file content: "
cat testfile1234
cat testfile1234 | wc -l | grep 2 && echo "-> mv operations: passed" || echo "-> mv operations: failed"
echo "Copied file content: "
cat testfile12345
cat testfile12345 | wc -l | grep 2 && echo "-> cp operations: passed" || echo "-> cp operations: failed"
rm -fv testfile12345 testfile1234


echo ">>> Compilations: use Burt test suite"
cat >test1.c <<EOF
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
 int fd, result;
 char* filename;

 if (argc != 2) {
   printf("Error: missing filename argument\n");
   exit(1);
 }

 filename = argv[1];
 fd = open(filename, O_CREAT|O_RDWR, "");

 if (fd == -1) {
   perror("Could not open file");
   exit(2);
 }

 char *buf = malloc(10240);
 memset(buf, 7, 10240);

 result = write(fd, buf, 10240);
 if (result == -1) {
   perror("Could not write");
   exit(3);
 }

 char *buf2 = malloc(1024);
 result = pread(fd, buf2, 30, 10200);
 printf("bytes read (should be 30): %d\n", result);
}
EOF
gcc test1.c -o test1
if [ -f test1 ] ; then
  echo "-> test1 compilation: passed"
  echo -n "Running test1: " && ./test1 test1.txt | grep 30 && echo "test1 run: passed" || echo "test1 run: failed"
else
  echo "-> test1 compilation: failed"
fi 
rm -f $workdir/test1*


cat > test2.c <<EOF
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
 int fd, result, fd2;
 char* filename;

 if (argc != 2) {
   printf("Error: missing filename argument\n");
   exit(1);
 }

 filename = argv[1];
 fd = open(filename, O_CREAT|O_RDWR);

 if (fd == -1) {
   perror("Could not open file");
   exit(2);
 }

 char *buf = malloc(10240);
 memset(buf, 7, 10240);

 result = write(fd, buf, 10240);
 if (result == -1) {
   perror("Could not write");
   exit(3);
 }

  if (fork() != 0) {
   char *buf2 = malloc(1024);

   fd2 = open(filename, O_RDONLY); 
   result = pread(fd2, buf2, 30, 10200);
   printf("bytes read (should be 30): %d\n", result);
  } 
}
EOF
gcc test2.c -o test2
if [ -f test2 ] ; then
  echo "-> test2 compilation: passed"
  echo -n "Running test2: " && ./test2 test2.txt |  grep ": 30" && echo "test1 run: passed" || echo "test1 run: failed"
else
  echo "-> test2 compilation: failed"
fi 
rm -f $workdir/test2*


cat > test3.c <<EOF
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  int readfd, writefd, result, pid;
  char* filename;
  char readbuf[50];

  if (argc != 2) {
    printf("Error: missing filename argument\n");
    exit(1);
  }

  filename = argv[1];  
  writefd = open(filename, O_WRONLY|O_CREAT|O_TRUNC, S_IRWXU|S_IRGRP|S_IROTH);

  if (writefd == -1) {
    perror("Could not open");
    exit(1);
  }

  char buf[10] = "1st write\n";
  result = write(writefd, buf, 10);
  pid = fork();
  if (pid == 0) {
    result = write(writefd, buf, 10);
    result = write(writefd, buf, 10);

    if (result == -1) {
      perror("Could not write");
      exit(1);
    }
  } else {
    wait(pid);
    readfd = open(filename, O_RDONLY);
    read(readfd, readbuf, 50);
    printf("----%s----\n", readbuf);
  }
  exit(0);
}
EOF

gcc test3.c -o test3
if [ -f test3 ] ; then
  echo "-> test3 compilation: passed"
  echo -n "Running test3: " && ./test3 test3.txt | grep write && echo "test1 run: passed" || echo "test1 run: failed"
else
  echo "-> test3 compilation: failed"
fi 


# xrdcp testing now
xrdcp -d 0 -f root://${XRDHOST}/$workdir/test3.c /dev/null >/dev/null 2>&1 && echo "-> xroot intefarce xrdcp: passed" || echo "-> xroot intefarce xrdcp: failed"

rm -f $workdir/test3*
rmdir $workdir

