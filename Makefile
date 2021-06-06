CC=clang
LD=llc
CFLAGS=-O2 -Wall

all: mark_to_classid.o priority_to_classid.o

mark_to_classid.o: mark_to_classid.c
	$(CC) $(CFLAGS) -target bpf -c mark_to_classid.c

priority_to_classid.o: priority_to_classid.c
	$(CC) $(CFLAGS) -target bpf -c priority_to_classid.c

clean:
	rm -f *.o
