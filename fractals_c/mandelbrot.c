#include <stdlib.h>
#include <stdio.h>
#include <math.h>

const int WIDTH = 4000;
const int HEIGHT = 3000;
const float LEFT_X = -2.05;
const float RIGHT_X = 0.75;
const float BOTTOM_Y = -1.25;
const float TOP_Y = 1.25;
const int NB_ITER = 80;

const int FILE_HEADER_SIZE = 14;
const int INFO_HEADER_SIZE = 40;
const int BYTES_PER_PIXEL = 3;

// https://stackoverflow.com/questions/2654480/writing-bmp-image-in-pure-c-c-without-other-libraries
// https://stackoverflow.com/questions/2438142/dynamic-memory-allocation-for-3d-array -- answer from il-bhima

typedef unsigned char byte;

typedef struct Complex
{
    float re;
    float im;
} complex;

typedef struct HSVColor
{
    float h;
    float s;
    float v;
} hsvcolor;

typedef struct RGBColor
{
    byte r;
    byte g;
    byte b;
} rgbcolor;

unsigned char* createBitmapFileHeader(int height, int stride)
{
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

unsigned char* createBitmapInfoHeader(int height, int width)
{
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

void generateBitmapImage(unsigned char* image, int height, int width, char* imageFileName)
{
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

float modulus(complex z) {
    return sqrt(z.re*z.re + z.im*z.im);
}

complex plus(complex z1, complex z2) {
    complex res;
    res.re = z1.re + z2.re;
    res.im = z1.im + z2.im;
    return res;
}

complex times(complex z1, complex z2) {
    complex res;
    res.re = z1.re*z2.re - z1.im*z2.im;
    res.im = z1.re*z2.im + z1.im*z2.re;
    return res;
}

int mandelbrot(complex c) {
    complex z;
    z.re = 0;
    z.im = 0;
    for (int n=0; n<NB_ITER; n++) {
        z = plus(times(z, z), c);
        if (modulus(z) > 2) return n;
    }
    return NB_ITER;
}

complex coords_to_complex(int i, int j) {
    complex c;
    i = (float)i;
    j = (float)j;
    c.re = LEFT_X + ((j / (float)WIDTH) * (RIGHT_X - LEFT_X));
    c.im = TOP_Y - ((i / (float)HEIGHT) * (TOP_Y - BOTTOM_Y));
    return c;
}

int offset(int i, int j, int color) {
    return WIDTH*BYTES_PER_PIXEL*i + BYTES_PER_PIXEL*j + color; 
}

rgbcolor hsv2rgb(hsvcolor c_in){
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


int main(int argc, char **argv) {

    char* filename = "mandelbrot_c.bmp";
    byte* image = (byte*)malloc(HEIGHT * WIDTH * BYTES_PER_PIXEL * sizeof(byte));

    // byte image[HEIGHT][WIDTH][BYTES_PER_PIXEL];
    
    /*
    byte*** image = (byte***)malloc(HEIGHT * sizeof(byte**));
    for (int n = 0; n < HEIGHT; n++) {
        image[n] = (byte**)malloc(WIDTH * sizeof(byte*));
        for (int m=0; m < WIDTH; m++) {
            image[n][m] = (byte*)malloc(BYTES_PER_PIXEL * sizeof(byte));
        }
    }
    */

    for (int i=0; i<HEIGHT; i++) {
        for (int j=0; j<WIDTH; j++) {
            complex c = coords_to_complex(i, j);
            int n_iter = mandelbrot(c);
            
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

    return 0;
}
