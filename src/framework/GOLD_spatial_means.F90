module GOLD_spatial_means

!***********************************************************************
!*                   GNU General Public License                        *
!* This file is a part of GOLD.                                        *
!*                                                                     *
!* GOLD is free software; you can redistribute it and/or modify it and *
!* are expected to follow the terms of the GNU General Public License  *
!* as published by the Free Software Foundation; either version 2 of   *
!* the License, or (at your option) any later version.                 *
!*                                                                     *
!* GOLD is distributed in the hope that it will be useful, but WITHOUT *
!* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  *
!* or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public    *
!* License for more details.                                           *
!*                                                                     *
!* For the full text of the GNU General Public License,                *
!* write to: Free Software Foundation, Inc.,                           *
!*           675 Mass Ave, Cambridge, MA 02139, USA.                   *
!* or see:   http://www.gnu.org/licenses/gpl.html                      *
!***********************************************************************

use GOLD_coms, only : EFP_type, operator(+), operator(-), assignment(=)
use GOLD_coms, only : EFP_to_real, real_to_EFP, EFP_list_sum_across_PEs
use GOLD_coms, only : query_EFP_overflow_error, reset_EFP_overflow_error
use GOLD_error_handler, only : GOLD_error, NOTE, WARNING, FATAL, is_root_pe
use GOLD_file_parser, only : get_param, log_version, param_file_type
use GOLD_grid, only : ocean_grid_type

implicit none ; private

#include <GOLD_memory.h>

public :: global_i_mean, global_j_mean

contains

subroutine global_i_mean(array, i_mean, G, mask)
  real, dimension(NXMEM_,NYMEM_), intent(in)    :: array
  real, dimension(NYMEM_),        intent(out)   :: i_mean
  type(ocean_grid_type),          intent(inout) :: G
  real, dimension(NXMEM_,NYMEM_), optional, intent(in) :: mask

!    This subroutine determines the global mean of a field along rows of
!  constant i, returning it in a 1-d array using the local indexing.

! Arguments: array - The 2-d array whose i-mean is to be taken.
!  (out)     i_mean - Global mean of array along its i-axis.
!  (in)      G - The ocean's grid structure.
!  (in)      mask - An array used for weighting the i-mean.

  type(EFP_type), allocatable, dimension(:) :: sum, mask_sum
  real :: mask_sum_r
  integer :: is, ie, js, je, Isq, Ieq, Jsq, Jeq, idg_off, jdg_off
  integer :: i, j

  is = G%isc ; ie = G%iec ; js = G%jsc ; je = G%jec
  idg_off = G%isd_global - G%isd ; jdg_off = G%jsd_global - G%jsd

  call reset_EFP_overflow_error()

  allocate(sum(G%jsg:G%jeg))
  if (present(mask)) then
    allocate(mask_sum(G%jsg:G%jeg))
  
    do j=G%jsg,G%jeg
      sum(j) = real_to_EFP(0.0) ; mask_sum(j) = real_to_EFP(0.0)
    enddo
  
    do i=is,ie ; do j=js,je
      sum(j+jdg_off) = sum(j+jdg_off) + real_to_EFP(array(i,j)*mask(i,j))
      mask_sum(j+jdg_off) = mask_sum(j+jdg_off) + real_to_EFP(mask(i,j))
    enddo ; enddo

    if (query_EFP_overflow_error()) call GOLD_error(FATAL, &
      "global_i_mean overflow error occurred before sums across PEs.")

    call EFP_list_sum_across_PEs(sum(G%jsg:G%jeg), G%jeg-G%jsg+1)
    call EFP_list_sum_across_PEs(mask_sum(G%jsg:G%jeg), G%jeg-G%jsg+1)

    if (query_EFP_overflow_error()) call GOLD_error(FATAL, &
      "global_i_mean overflow error occurred during sums across PEs.")
    
    do j=js,je
      mask_sum_r = EFP_to_real(mask_sum(j+jdg_off))
      if (mask_sum_r == 0.0 ) then ; i_mean(j) = 0.0 ; else
        i_mean(j) = EFP_to_real(sum(j+jdg_off)) / mask_sum_r
      endif
    enddo
    
    deallocate(mask_sum)
  else
    do j=G%jsg,G%jeg ; sum(j) = real_to_EFP(0.0) ; enddo
  
    do i=is,ie ; do j=js,je
      sum(j+jdg_off) = sum(j+jdg_off) + real_to_EFP(array(i,j))
    enddo ; enddo

    if (query_EFP_overflow_error()) call GOLD_error(FATAL, &
      "global_i_mean overflow error occurred before sum across PEs.")

    call EFP_list_sum_across_PEs(sum(G%jsg:G%jeg), G%jeg-G%jsg+1)

    if (query_EFP_overflow_error()) call GOLD_error(FATAL, &
      "global_i_mean overflow error occurred during sum across PEs.")

    do j=js,je
      i_mean(j) = EFP_to_real(sum(j+jdg_off)) / real(G%ieg-G%isg+1)
    enddo
  endif

  deallocate(sum)

end subroutine global_i_mean

subroutine global_j_mean(array, j_mean, G, mask)
  real, dimension(NXMEM_,NYMEM_), intent(in)    :: array
  real, dimension(NXMEM_),        intent(out)   :: j_mean
  type(ocean_grid_type),          intent(inout) :: G
  real, dimension(NXMEM_,NYMEM_), optional, intent(in) :: mask

!    This subroutine determines the global mean of a field along rows of
!  constant j, returning it in a 1-d array using the local indexing.

! Arguments: array - The 2-d array whose j-mean is to be taken.
!  (out)     j_mean - Global mean of array along its j-axis.
!  (in)      G - The ocean's grid structure.
!  (in)      mask - An array used for weighting the j-mean.

  type(EFP_type), allocatable, dimension(:) :: sum, mask_sum
  real :: mask_sum_r
  integer :: is, ie, js, je, Isq, Ieq, Jsq, Jeq, idg_off, jdg_off
  integer :: i, j

  is = G%isc ; ie = G%iec ; js = G%jsc ; je = G%jec
  idg_off = G%isd_global - G%isd ; jdg_off = G%jsd_global - G%jsd

  call reset_EFP_overflow_error()

  allocate(sum(G%isg:G%ieg))
  if (present(mask)) then
    allocate (mask_sum(G%isg:G%ieg))
  
    do i=G%isg,G%ieg
      sum(i) = real_to_EFP(0.0) ; mask_sum(i) = real_to_EFP(0.0)
    enddo
  
    do i=is,ie ; do j=js,je
      sum(i+idg_off) = sum(i+idg_off) + real_to_EFP(array(i,j)*mask(i,j))
      mask_sum(i+idg_off) = mask_sum(i+idg_off) + real_to_EFP(mask(i,j))
    enddo ; enddo

    if (query_EFP_overflow_error()) call GOLD_error(FATAL, &
      "global_j_mean overflow error occurred before sums across PEs.")

    call EFP_list_sum_across_PEs(sum(G%isg:G%ieg), G%ieg-G%isg+1)
    call EFP_list_sum_across_PEs(mask_sum(G%isg:G%ieg), G%ieg-G%isg+1)
    
    if (query_EFP_overflow_error()) call GOLD_error(FATAL, &
      "global_j_mean overflow error occurred during sums across PEs.")
    
    do i=is,ie
      mask_sum_r = EFP_to_real(mask_sum(i+idg_off))
      if (mask_sum_r == 0.0 ) then ; j_mean(i) = 0.0 ; else
        j_mean(i) = EFP_to_real(sum(i+idg_off)) / mask_sum_r
      endif
    enddo
    
    deallocate(mask_sum)
  else
    do i=G%isg,G%ieg ; sum(i) = real_to_EFP(0.0) ; enddo
  
    do i=is,ie ; do j=js,je
      sum(i+idg_off) = sum(i+idg_off) + real_to_EFP(array(i,j))
    enddo ; enddo

    if (query_EFP_overflow_error()) call GOLD_error(FATAL, &
      "global_j_mean overflow error occurred before sum across PEs.")

    call EFP_list_sum_across_PEs(sum(G%isg:G%ieg), G%ieg-G%isg+1)

    if (query_EFP_overflow_error()) call GOLD_error(FATAL, &
      "global_j_mean overflow error occurred during sum across PEs.")

    do i=is,ie
      j_mean(i) = EFP_to_real(sum(i+idg_off)) / real(G%jeg-G%jsg+1)
    enddo
  endif

  deallocate(sum)

end subroutine global_j_mean

end module GOLD_spatial_means
