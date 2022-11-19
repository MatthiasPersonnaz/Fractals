#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <cuda/std/complex>

#define N 10000
#define MAX_ERR 1e-6


__global__ void vector_add(float *out, float *a, float *b, int n) {
    for(int i = 0; i < n; i++){
        out[i] = a[i] + b[i];
    }
}



int main(){
    float *a, *b, *out;
    float *d_a, *d_b, *d_out;

    // Allocate memory
    a   = (float*)malloc(sizeof(float) * N);
    b   = (float*)malloc(sizeof(float) * N);
    out = (float*)malloc(sizeof(float) * N);

    // Allocate memory on the GPU
    cudaMalloc((void**)&d_a, sizeof(float) * N);
    cudaMalloc((void**)&d_b, sizeof(float) * N);
    cudaMalloc((void**)&d_out, sizeof(float) * N);

    // Initialize array
    for(int i = 0; i < N; i++){
        a[i] = 1.0f;
        b[i] = 2.0f;
    }

    // Transfer data onto the GPU memory
    cudaMemcpy(d_a, a, sizeof(float)*N, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b, sizeof(float)*N, cudaMemcpyHostToDevice);

    // Main function
    // vector_add(out, a, b, N);
    vector_add<<<1, 1>>>(d_out, d_a, d_b, N);

    // Verification
    for(int i = 0; i < N; i++){
        assert(fabs(out[i] - a[i] - b[i]) < MAX_ERR);
    }

    printf("out[0] = %f\n", out[0]);
    printf("PASSED\n");
}
