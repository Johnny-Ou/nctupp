#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>

__global__ void mandelKernel(float lowerX, float lowerY, float stepX, float stepY, int width, int* img, int maxIterations) {
    // To avoid error caused by the floating number, use the following pseudo code
    //
    // float x = lowerX + thisX * stepX;
    // float y = lowerY + thisY * stepY;

    int thisX = blockIdx.x * blockDim.x + threadIdx.x;
    int thisY = blockIdx.y * blockDim.y + threadIdx.y;
    float x = lowerX + thisX * stepX;
    float y = lowerY + thisY * stepY;
    int index = thisY * width + thisX;
    
    // img[nidex] = mandel(x, y, maxIterations);
    float tempX = x;
    float tempY = y;
    int i;
    for (i = 0; i < maxIterations; ++i)
    {

        if (tempX * tempX + tempY * tempY > 4.f)
        break;

        float new_tempX = tempX * tempX - tempY * tempY;
        float new_tempY = 2.f * tempX * tempY;
        tempX = x + new_tempX;
        tempY = y + new_tempY;
    }
    
    img[index] = i;
}

// Host front-end function that allocates the memory and launches the GPU kernel
void hostFE (float upperX, float upperY, float lowerX, float lowerY, int* img, int resX, int resY, int maxIterations)
{
    float stepX = (upperX - lowerX) / resX;
    float stepY = (upperY - lowerY) / resY;

    int *h_img, *d_img;

    h_img = (int *)malloc(resX * resY * sizeof(int));
    cudaMalloc((void **)&d_img, resX * resY * sizeof(int));

    dim3 threadsPerBlock(16, 16);
    dim3 numBlock(resX/threadsPerBlock.x, resY/threadsPerBlock.y);

    mandelKernel<<<numBlock, threadsPerBlock>>>(lowerX, lowerY, stepX, stepY, resX, d_img, maxIterations);
    cudaMemcpy(h_img, d_img, resX * resY * sizeof(int), cudaMemcpyDeviceToHost);
    memcpy(img, h_img, resX * resY * sizeof(int));

    cudaFree(d_img);
    free(h_img);
}