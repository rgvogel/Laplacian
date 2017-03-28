/*
 * dotproduct.cu
 * includes setup funtion called from "driver" program
 * also includes kernel function 'kernel_dotproduct[2]()'
 * largely inspired in the pdf http://www.cuvilib.com/Reduction.pdf
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#define BLOCK_SIZE 1024

struct timeval  tp1, tp2;
#define GPU_ERR_CHK(ans) { gpu_assert((ans), __FILE__, __LINE__); }
static void gpu_assert(cudaError_t code, const char *file, int line,
        bool abort = true) {
    if (code != cudaSuccess) {
        fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code),
                file, line);
        if (abort) {
            exit(code);
        }
    }
}
__global__ void kernel_laplacian(float *lap,long long size, int tUnit) {
    extern __shared__ float lapd[];
    
    int bid = blockDim.x;
    int nTotalThreads;
    nTotalThreads= 0;
    if (!bid){
	nTotalThreads = bid;
    }else{
	//(0 == 2^0)
    	int x = 1;
    	while(x < bid)
    	{
      	    x <<= 1;
    	}
        nTotalThreads = x;
    }

    // each thread loads one element from global to shared mem
    unsigned int tid = threadIdx.x;
    long long i = blockIdx.x*nTotalThreads + threadIdx.x;
    lapd[tid] = 1;
    if(i < size){
    	lapd[tid]= (lap[i-1]+lap[i+1])/2;
	if(i==(size-1)){
    		lapd[tid]= (lap[i-1]+23)/2;
	}
    }
    __syncthreads();
    if(i && i < size){
    	lap[i] = lapd[tid];}
   
}



// This function is called from the host computer.
// It manages memory and calls the function that is executed on the GPU
extern "C" void cuda_laplacian(float *lap,long long arraySize, int tUnit, double*time_result)
{
	// force_d, distance_d and result_d are the GPU counterparts of the arrays that exists in host memory 
	float *lap_d;
	

	

	// Reset the device and exit
    	GPU_ERR_CHK(cudaDeviceReset());

    		
	// allocate space in the device 
	GPU_ERR_CHK(cudaMalloc ((void**) &lap_d, sizeof(float) * arraySize));
        
	
	//copy the arrays from host to the device 
	GPU_ERR_CHK(cudaMemcpy (lap_d, lap, sizeof(float) * arraySize, cudaMemcpyHostToDevice));

	
	int threads;
	if(arraySize < 128){
		threads = 64;
	} else if (arraySize < 256 ){
		threads = 128;
	} else if (arraySize < 512){
		threads = 256;
	} else if (arraySize < 1024){
		threads = 512;
	} else {
		threads = BLOCK_SIZE;
	}
	long long block_size = threads;
        long long blocks = ceil(arraySize / ((float) block_size));
	// set execution configuration
        dim3 dimblock (block_size);
        dim3 dimgrid (blocks);
        int smemSize = dimblock.x * sizeof(long long);
        
	// actual computation: Call the kernel
	gettimeofday(&tp1, NULL);
	int i;
	for(i=0; i<tUnit;i++){
        kernel_laplacian<<<dimgrid,dimblock,smemSize>>>(lap_d, arraySize,tUnit);
                  
	} 
       //copy the arrays from host to the device
        GPU_ERR_CHK(cudaMemcpy (lap, lap_d, sizeof(float) * arraySize, cudaMemcpyDeviceToHost));
	gettimeofday(&tp2, NULL);
    	*time_result = (double) (tp2.tv_usec - tp1.tv_usec) / 1000000 + (double) (tp2.tv_sec - tp1.tv_sec);
       cudaFree(lap_d); 
}

