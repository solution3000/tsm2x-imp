/*
  kernels.cu -- TSM2 Kernels -- as declared in multiply.cuh
  by Cody Rivera
 */

#include "cuda_runtime.h"
#include "multiply.cuh"




template <int t1, int t2, int t3>
__global__ void floatTSM2Kernel(const float* A, const float* B, float* C,
                                const unsigned int n, const unsigned int k)
{
    // Names mostly follow the published code
    __shared__ float currB[t1 * t2];
    
    float currA[t3];
    float nextA[t3];
    float nextB[t2];
    float currC[t2];
        
    const int tid = threadIdx.x;
    int threadBase = (blockIdx.x * blockDim.x);
    int thread;
    
    // This implementation can respond to arbitrary input

    // We cannot rule out a thread's participation based on
    // whether it corresponds to a row in Matrix A, so we
    // introduce threadBase.
    for (; threadBase < n; threadBase += blockDim.x * gridDim.x)
    {
        thread = threadBase + tid;
        for (int p = 0; p < k; p += t2)
        {
            // Load loops have extra conditionals to ensure
            // they do not make bad memory accesses
            
            // Loads first tile of output registers and A
            if (thread < n)
            {
                #pragma unroll
                for (int i = 0; i < t2; ++i)
                {
                    if (p + i < k)
                    {
                        currC[i] = C[thread + ((p + i) * n)];
                    }
                }
                // Loads currA
                #pragma unroll
                for (int i = 0; i < t3; ++i)
                {
                    if (i < n)
                    {
                        currA[i] = A[thread + (i * n)];
                    }
                }
            }
            // Loads tile of B
            if (tid < n)
            {
                #pragma unroll
                for (int i = 0; i < t2; ++i)
                {
                    if (p + i < k)
                    {
                        currB[tid + (i * t1)] = B[tid + ((p + i) * n)];
                    }
                }
            }

            // Outer product loop
            for (int j = 0; j < n; j += t1)
            {
                __syncthreads();
                // Loads next tile of B
                if (j + t1 + tid < n)
                {
                    #pragma unroll
                    for (int i = 0; i < t2; ++i)
                    {
                        if (p + i < k)
                        {
                            nextB[i] = B[(j + t1 + tid) + ((p + i) * n)]; 
                        }
                    }
                }
                
                // Loop over A's columns 
                for (int l = j; l < j + t1 && l < n; l += t3)
                {
                    // Loads next A
                    #pragma unroll
                    for (int i = 0; i < t3; ++i)
                    {
                        if (l + t3 + i < n && thread < n)
                        {
                            nextA[i] = A[thread + ((l + t3 + i) * n)];
                        }
                    }
                                        
                    // Floating Point Operations (lines 32-34)
                    // Each thread does t2 * t3 mults
                    #pragma unroll
                    for (int i = 0; i < t2; ++i)
                    {
                        #pragma unroll
                        for (int k = 0; k < t3; ++k)
                        {
                            currC[i] += currA[k] * currB[(l - j) + k + (i * t1)]; 
                        }
                    }
                    
                    // Stores next A in curr A
                    #pragma unroll
                    for (int i = 0; i < t3; ++i)
                    {
                        currA[i] = nextA[i];
                    }
                }
                __syncthreads();

                // Loads currB from each thread's nextB
                #pragma unroll
                for (int i = 0; i < t2; ++i)
                {
                    currB[tid + (i * t1)] = nextB[i];
                }
            }
            // Stores C
            if (thread < n)
            {
                #pragma unroll
                for (int i = 0; i < t2 && (p + i < k); ++i)
                {
                    C[thread + ((p + i) * n)] = currC[i];
                }
            }
        }
    }    
}

template <int t1, int t2, int t3>
__global__ void doubleTSM2Kernel(const double* A, const double* B, double* C,
                                 const unsigned int n, const unsigned int k)
{
    
    // Names mostly follow the published code
    __shared__ double currB[t1 * t2];
    
    double currA[t3];
    double nextA[t3];
    double nextB[t2];
    double currC[t2];
        
    const int tid = threadIdx.x;
    int threadBase = (blockIdx.x * blockDim.x);
    int thread;
    
    // This implementation can respond to arbitrary input

    
    // We cannot rule out a thread's participation based on
    // whether it corresponds to a row in Matrix A, so we
    // introduce threadBase.
    for (; threadBase < n; threadBase += blockDim.x * gridDim.x)
    {
        thread = threadBase + tid;
        for (int p = 0; p < k; p += t2)
        {
            // Load loops have extra conditionals to ensure
            // they do not make bad memory accesses
            
            // Loads first tile of output registers and A
            if (thread < n)
            {
                #pragma unroll
                for (int i = 0; i < t2; ++i)
                {
                    if (p + i < k)
                    {
                        currC[i] = C[thread + ((p + i) * n)];
                    }
                }
                // Loads currA
                #pragma unroll
                for (int i = 0; i < t3; ++i)
                {
                    if (i < n)
                    {
                        currA[i] = A[thread + (i * n)];
                    }
                }
            }
            // Loads tile of B
            if (tid < n)
            {
                #pragma unroll
                for (int i = 0; i < t2; ++i)
                {
                    if (p + i < k)
                    {
                        currB[tid + (i * t1)] = B[tid + ((p + i) * n)];
                    }
                }
            }

            // Outer product loop
            for (int j = 0; j < n; j += t1)
            {
                __syncthreads();
                // Loads next tile of B
                if (j + t1 + tid < n)
                {
                    #pragma unroll
                    for (int i = 0; i < t2; ++i)
                    {
                        if (p + i < k)
                        {
                            nextB[i] = B[(j + t1 + tid) + ((p + i) * n)]; 
                        }
                    }
                }
                
                // Loop over A's columns 
                for (int l = j; l < j + t1 && l < n; l += t3)
                {
                    // Loads next A
                    #pragma unroll
                    for (int i = 0; i < t3; ++i)
                    {
                        if (l + t3 + i < n && thread < n)
                        {
                            nextA[i] = A[thread + ((l + t3 + i) * n)];
                        }
                    }
                                        
                    // Floating Point Operations (lines 32-34)
                    // Each thread does t2 * t3 mults
                    #pragma unroll
                    for (int i = 0; i < t2; ++i)
                    {
                        #pragma unroll
                        for (int k = 0; k < t3; ++k)
                        {
                            currC[i] += currA[k] * currB[(l - j) + k + (i * t1)]; 
                        }
                    }
                    
                    // Stores next A in curr A
                    #pragma unroll
                    for (int i = 0; i < t3; ++i)
                    {
                        currA[i] = nextA[i];
                    }
                }
                __syncthreads();

                // Loads currB from each thread's nextB
                #pragma unroll
                for (int i = 0; i < t2; ++i)
                {
                    currB[tid + (i * t1)] = nextB[i];
                }
            }
            // Stores C
            if (thread < n)
            {
                #pragma unroll
                for (int i = 0; i < t2 && (p + i < k); ++i)
                {
                    C[thread + ((p + i) * n)] = currC[i];
                }
            }
        }
    }
}



