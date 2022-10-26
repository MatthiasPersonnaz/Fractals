src_name = mandelbrot.cu
exec_name = mandelbrot_cu
bmp_name = mandelbrot_cu.bmp
png_name = mandelbrot_cu.png
CC = nvcc
CFLAGS = -O2

all: build exec convert
.PHONY: all 

build:
	$(CC) $(src_name) $(CFLAGS) -o $(exec_name)

exec:
	./$(exec_name)

convert:
	convert $(bmp_name) $(png_name)
	rm $(bmp_name)

clean:
	rm $(exec_name) $(bmp_name) $(png_name)
