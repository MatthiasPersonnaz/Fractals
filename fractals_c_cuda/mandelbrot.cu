// Compile with
// nvcc mandelbrot.cu -o mandelbrot -ccbin "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.33.31629\bin\Hostx64\x64" -O2

//#include <stdlib.h>
#include <stdio.h>
//#include <math.h>

#include <cuda/std/complex>

typedef unsigned char  byte;   // 0..255
typedef unsigned short ushort; // 0..65535
typedef unsigned int   uint;   // 0..4294967295

typedef struct HSVColor {
    float h;
    float s;
    float v;
} hsvcolor;

typedef struct RGBColor {
    byte r;
    byte g;
    byte b;
} rgbcolor;

// window dimensions and bounds
const int   WIDTH    = 4000;
const int   HEIGHT   = 3000;
const float LEFT_X   = -1.65;
const float RIGHT_X  = +1.65;
const float BOTTOM_Y = -1.2;
const float TOP_Y    =  1.2;

// maximum number of iterations
const ushort NB_ITER = 256;
const float C_REAL = -0.8;
const float C_IMAG = +0.156;

// output file
const char* filename = "mandelbrot_cu.bmp";

// bitmap file specifications
const int FILE_HEADER_SIZE = 14;
const int INFO_HEADER_SIZE = 40;
const int BYTES_PER_PIXEL  = 3;


unsigned char* createBitmapFileHeader(int height, int stride) {
    int fileSize = FILE_HEADER_SIZE + INFO_HEADER_SIZE + (stride * height);

    static unsigned char fileHeader[] = {
        0,0,     /// signature
        0,0,0,0, /// image file size in bytes
        0,0,0,0, /// reserved
        0,0,0,0, /// start of pixel array
    };

    fileHeader[ 0] = (unsigned char)('B');
    fileHeader[ 1] = (unsigned char)('M');
    fileHeader[ 2] = (unsigned char)(fileSize      );
    fileHeader[ 3] = (unsigned char)(fileSize >>  8);
    fileHeader[ 4] = (unsigned char)(fileSize >> 16);
    fileHeader[ 5] = (unsigned char)(fileSize >> 24);
    fileHeader[10] = (unsigned char)(FILE_HEADER_SIZE + INFO_HEADER_SIZE);

    return fileHeader;
}

unsigned char* createBitmapInfoHeader(int height, int width) {
    static unsigned char infoHeader[] = {
        0,0,0,0, /// header size
        0,0,0,0, /// image width
        0,0,0,0, /// image height
        0,0,     /// number of color planes
        0,0,     /// bits per pixel
        0,0,0,0, /// compression
        0,0,0,0, /// image size
        0,0,0,0, /// horizontal resolution
        0,0,0,0, /// vertical resolution
        0,0,0,0, /// colors in color table
        0,0,0,0, /// important color count
    };

    infoHeader[ 0] = (unsigned char)(INFO_HEADER_SIZE);
    infoHeader[ 4] = (unsigned char)(width      );
    infoHeader[ 5] = (unsigned char)(width >>  8);
    infoHeader[ 6] = (unsigned char)(width >> 16);
    infoHeader[ 7] = (unsigned char)(width >> 24);
    infoHeader[ 8] = (unsigned char)(height      );
    infoHeader[ 9] = (unsigned char)(height >>  8);
    infoHeader[10] = (unsigned char)(height >> 16);
    infoHeader[11] = (unsigned char)(height >> 24);
    infoHeader[12] = (unsigned char)(1);
    infoHeader[14] = (unsigned char)(BYTES_PER_PIXEL*8);

    return infoHeader;
}

void generateBitmapImage(unsigned char* image, int height, int width, const char* imageFileName) {
    int widthInBytes = width * BYTES_PER_PIXEL;

    unsigned char padding[3] = {0, 0, 0};
    int paddingSize = (4 - (widthInBytes) % 4) % 4;

    int stride = (widthInBytes) + paddingSize;

    FILE* imageFile = fopen(imageFileName, "wb");

    unsigned char* fileHeader = createBitmapFileHeader(height, stride);
    fwrite(fileHeader, 1, FILE_HEADER_SIZE, imageFile);

    unsigned char* infoHeader = createBitmapInfoHeader(height, width);
    fwrite(infoHeader, 1, INFO_HEADER_SIZE, imageFile);

    for (int i = 0; i < height; i++) {
        fwrite(image + (i*widthInBytes), BYTES_PER_PIXEL, width, imageFile);
        fwrite(padding, 1, paddingSize, imageFile);
    }

    fclose(imageFile);
}

rgbcolor hsv2rgb(hsvcolor c_in) {
    float h = c_in.h;
    float s = c_in.s;
    float v = c_in.v;
    float r, g, b;

    float i = floor(h * 6);
    float f = h * 6 - i;
    float p = v * (1 - s);
    float q = v * (1 - f * s);
    float t = v * (1 - (1 - f) * s);

    switch((int)i % 6){
        case 0: r = v, g = t, b = p; break;
        case 1: r = q, g = v, b = p; break;
        case 2: r = p, g = v, b = t; break;
        case 3: r = p, g = q, b = v; break;
        case 4: r = t, g = p, b = v; break;
        case 5: r = v, g = p, b = q; break;
    }

    rgbcolor c_out;
    c_out.r = (int)(r * 255);
    c_out.g = (int)(g * 255);
    c_out.b = (int)(b * 255);

    return c_out;
}

__global__ void mandel_iter(ushort *iter) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    
    // handling arbitrary vector size
    if (tid < WIDTH * HEIGHT) {
        // compute coords
        float i = (float)(tid / WIDTH);
        float j = (float)(tid % WIDTH);
        
        // compute complex
        cuda::std::complex<float> z(LEFT_X + ((j / (float)WIDTH) * (RIGHT_X - LEFT_X)),
                                    TOP_Y - ((i / (float)HEIGHT) * (TOP_Y - BOTTOM_Y)));
        
        // execute algorithm
        cuda::std::complex<float> c(C_REAL, C_IMAG);
        ushort n = 0;
        while ((abs(z) < 2.) && (n < NB_ITER)) {
            z = z*z + c;
            n += 1;
        }
        iter[tid] = n;
    }
}

int offset(int i, int j, int color) {
    return WIDTH*BYTES_PER_PIXEL*i + BYTES_PER_PIXEL*j + color; 
}

int main(int argc, char **argv) {

    // arrays storing the number of iterations for each pixel
    ushort *h_iter;
    ushort *d_iter;
    size_t size_iter = WIDTH * HEIGHT * sizeof(ushort);
    
    // allocate host memory
    h_iter = (ushort*)malloc(size_iter);
    
    // allocate device memory
    cudaMalloc((void**)&d_iter, size_iter);
    
    // transfer data from host memory to device memory
    cudaMemcpy(d_iter, h_iter, size_iter, cudaMemcpyHostToDevice);
    
    // executing kernel
    int block_size = 512;
    int grid_size = ((WIDTH*HEIGHT + block_size) / block_size);
    mandel_iter<<<grid_size, block_size>>>(d_iter);
    
    // transfer data back to host memory
    cudaMemcpy(h_iter, d_iter, size_iter, cudaMemcpyDeviceToHost);

    // generate RGB bitmap image
    byte* image = (byte*)malloc(HEIGHT * WIDTH * BYTES_PER_PIXEL * sizeof(byte));
    for (int i=0; i<HEIGHT; i++) {
        for (int j=0; j<WIDTH; j++) {
            int n_iter = h_iter[i*WIDTH + j];
            //printf("%d\n", n_iter);
            
            hsvcolor hsv;
            hsv.h = (float)n_iter / (float)NB_ITER;
            hsv.s = 1.0;
            if (n_iter < NB_ITER) { hsv.v = 1.0; } else { hsv.v = 0.0; }
            rgbcolor rgb = hsv2rgb(hsv);
            
            image[offset(i, j, 0)] = (byte)(rgb.r); // red
            image[offset(i, j, 1)] = (byte)(rgb.g); // green
            image[offset(i, j, 2)] = (byte)(rgb.b); // blue
        }
    }
    generateBitmapImage((byte*)image, HEIGHT, WIDTH, filename);
    free(image);
    
    // deallocate device memory
    cudaFree(d_iter);

    // deallocate host memory
    free(h_iter);

    return 0;
}
