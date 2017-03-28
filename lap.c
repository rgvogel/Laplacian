/*
 * blockAndthread.c
 * A "driver" program that calls a routine (i.e. a kernel)
 * that executes on the GPU.  The kernel fills two int arrays
 * with the block ID and the thread ID
 *
 * Note: the kernel code is found in the file 'blockAndThread.cu'
 * compile both driver code and kernel code with nvcc, as in:
 * 			nvcc blockAndThread.c blockAndThread.cu
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

//#define SIZEOFARRAY 10240000

struct timeval  ts1, ts2, tps1, tps2;
// The serial function dotproduct

void serial_laplacian(float *lap,long long size, int tUnit, float *result)
{
    int i;
    int j;
    float L;
    float R;
    result[0] =100;  
   for(j =0; j<tUnit; j++){
       for (i = 1; i < size; i++){
	  L = lap[i-1];
	  R = lap[i+1];
	  //printf("%d \n", L);

	  if (i==size-1){
		result[i]= (L +23)/2;
		lap[i]= (L +23)/2;}
	  else	{
                result[i] =(L + R)/2;
		lap[i] = (L + R)/2;}
	 // printf("%f \n", result[i]);
       }
   }
}

// The function dotproduct is in the file dotproduct.cu
//extern void cuda_laplacian(float *lap,long long size, int tUnit, float *result);

int main (int argc, char *argv[])
{
    long long SIZEOFARRAY;
    SIZEOFARRAY = 10;
    if (argc !=  2){
    	printf("Usage: dotproduct <array_size>\n");
	exit(2);
    }else{
        SIZEOFARRAY = atoll(argv[1]);
    }
    //timeval tv1, tv2;
    // Declare arrays and initialize to 0
   int tUnit;
   float*lap;
    lap = (float*)malloc(SIZEOFARRAY*sizeof(long long));
    float *result_array;
    result_array = (float*)malloc(SIZEOFARRAY*sizeof(long long));
    gettimeofday(&tps1, NULL);
    // Here's where I could setup the arrays.
    long long i;
    lap[0] = 100;
    for (i=1; i < SIZEOFARRAY; i++) {
       lap[i]= 23;
    }
    
    gettimeofday(&tps2, NULL);
    double tps_time = (double) (tps2.tv_usec - tps1.tv_usec) / 1000000 + (double) (tps2.tv_sec - tps1.tv_sec);
    tUnit = 1000000;
    // Serial dotproduct
    int u;
    //long long serial_result = 0;
    /*for( u = 0; u<1000; u = u+10){
    gettimeofday(&ts1, NULL);
    serial_laplacian(lap, SIZEOFARRAY,u, result_array);
    gettimeofday(&ts2, NULL);
    double ts_time = (double) (ts2.tv_usec - ts1.tv_usec) / 1000000 + (double) (ts2.tv_sec - ts1.tv_sec);
printf("%f\n",ts_time);}*/
    FILE*f =fopen("lapOut.csv","w");
	int j;
	
    // Call the function that will call the GPU function
   for( i=0; i<100000; i= i+100){
	
    double cuda_time_result = 0.0; 
	tUnit = i;
	 cuda_laplacian(lap, SIZEOFARRAY,tUnit, &cuda_time_result);
    //printf("%f\n",cuda_time_result);
   // long long cuda_result = 0;
    for (j= 0; j < SIZEOFARRAY; j++){    
    	
	fprintf(f,"%f, ",lap[j]);
    }
    fprintf(f,"\n");
}
    fclose(f);
    return 0;
}

