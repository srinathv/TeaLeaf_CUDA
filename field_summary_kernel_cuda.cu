/*Crown Copyright 2012 AWE.
 * 
 * This file is part of CloverLeaf.
 *
 * CloverLeaf is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * CloverLeaf is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * CloverLeaf. If not, see http://www.gnu.org/licenses/.
 */

/*
 *  @brief CUDA field summary kernel
 *  @author Michael Boulton NVIDIA Corporation
 *  @details The total mass, internal energy, kinetic energy and volume weighted
 *  pressure for the chunk is calculated.
 */

#include "cuda_common.hpp"
#include "kernel_files/field_summary_kernel.cuknl"

extern "C" void field_summary_kernel_cuda_
(double* vol, double* mass, double* ie, double* ke, double* press, double* temp)
{
    chunk.field_summary_kernel(vol, mass, ie, ke, press, temp);
}

void CloverleafCudaChunk::field_summary_kernel
(double* vol, double* mass, double* ie, double* ke, double* press, double* temp)
{
    CUDA_BEGIN_PROFILE;

    device_field_summary_kernel_cuda<<< num_blocks, BLOCK_SZ >>>
    (x_min, x_max, y_min, y_max, volume, density0,
        energy0, pressure, xvel0, yvel0,
        work_array_1, work_array_2, work_array_3,
        work_array_4, work_array_5, work_array_6);
    CUDA_ERR_CHECK;

    *vol = thrust::reduce(reduce_ptr_1,
                          reduce_ptr_1 + num_blocks,
                          0.0);

    *mass = thrust::reduce(reduce_ptr_2,
                           reduce_ptr_2 + num_blocks,
                           0.0);

    *ie = thrust::reduce(reduce_ptr_3,
                         reduce_ptr_3 + num_blocks,
                         0.0);

    *ke = thrust::reduce(reduce_ptr_4,
                         reduce_ptr_4 + num_blocks,
                         0.0);

    *press = thrust::reduce(reduce_ptr_5,
                            reduce_ptr_5 + num_blocks,
                            0.0);

    *press = thrust::reduce(reduce_ptr_6,
                            reduce_ptr_6 + num_blocks,
                            0.0);

    CUDA_END_PROFILE;
}
