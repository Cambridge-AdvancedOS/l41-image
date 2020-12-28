OBJDIR=obj

all:
	@mkdir -p ${OBJDIR}
	cc -c src/crc32.c -o ${OBJDIR}/crc32.o
	cc -c src/mkenvimage.c -o ${OBJDIR}/mkenvimage.o
	cc ${OBJDIR}/crc32.o ${OBJDIR}/mkenvimage.o -o ${OBJDIR}/mkenvimage

clean:
	@rm -rf ${OBJDIR}/*
