module lock_exchange_initialization
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

!***********************************************************************
!*                                                                     *
!*  The module configures the model for the "lock_exchange" experiment.         *
!*  lock_exchange = Dense Overflow and Mixing Experiment?                       *
!*                                                                     *
!********+*********+*********+*********+*********+*********+*********+**

use GOLD_error_handler, only : GOLD_mesg, GOLD_error, FATAL, is_root_pe
use GOLD_file_parser, only : get_param, log_version, param_file_type
use GOLD_grid, only : ocean_grid_type
use GOLD_tracer, only : add_tracer_OBC_values, advect_tracer_CS
use GOLD_variables, only : thermo_var_ptrs, directories
implicit none ; private

#include <GOLD_memory.h>

public lock_exchange_initialize_thickness

contains

! -----------------------------------------------------------------------------
subroutine lock_exchange_initialize_thickness(h, G, param_file)
  real, intent(out), dimension(NXMEM_,NYMEM_, NZ_) :: h
  type(ocean_grid_type), intent(in) :: G
  type(param_file_type), intent(in) :: param_file
! Arguments: h - The thickness that is being initialized.
!  (in)      G - The ocean's grid structure.
!  (in)      param_file - A structure indicating the open file to parse for
!                         model parameter values.

!  This subroutine initializes layer thicknesses for the lock_exchange experiment
  real :: e0(SZK_(G))     ! The resting interface heights, in m, usually !
                          ! negative because it is positive upward.      !
  real :: e_pert(SZK_(G)) ! Interface height perturbations, positive     !
                          ! upward, in m.                                !
  real :: eta1D(SZK_(G)+1)! Interface height relative to the sea surface !
                          ! positive upward, in m.                       !
  real :: max_depth  ! The minimum depth in m.
  real :: len_lon, west_lon ! Length of domain, position of western boundary
  real :: front_displacement ! Vertical displacement acrodd front
  real :: thermocline_thickness ! Thickness of stratified region
  character(len=40)  :: mod = "lock_exchange_initialize_thickness" ! This subroutine's name.
  integer :: i, j, k, is, ie, js, je, nz

  is = G%isc ; ie = G%iec ; js = G%jsc ; je = G%jec ; nz = G%ke

  call GOLD_mesg("  lock_exchange_initialization.F90, lock_exchange_initialize_thickness: setting thickness", 5)

  call get_param(param_file, mod, "MAXIMUM_DEPTH", max_depth, &
                 "The maximum depth of the ocean.", units="m", &
                 fail_if_missing=.true.)
  call get_param(param_file, mod, "WESTLON", west_lon, &
                 "The western longitude of the domain.", units="degrees", &
                 default=0.0)
  call get_param(param_file, mod, "LENLON", len_lon, &
                 "The longitudinal length of the domain.", units="degrees", &
                 fail_if_missing=.true.)
  call get_param(param_file, mod, "FRONT_DISPLACEMENT", front_displacement, &
                 "The vertical displacement of interfaces across the front. \n"//&
                 "A value larger in magnitude that MAX_DEPTH is truncated,", &
                 units="m", fail_if_missing=.true.)
  call get_param(param_file, mod, "THERMOCLINE_THICKNESS", thermocline_thickness, &
                 "The thickness of the thermocline in the lock exchange \n"//&
                 "experiment.  A value of zero creates a two layer system \n"//&
                 "with vanished layers in between the two inflated layers.", &
                 default=0., units="m")

  do j=G%jsc,G%jec ; do i=G%isc,G%iec
    do k=2,nz
      eta1D(K) = -0.5 * max_depth & ! Middle of column
              - thermocline_thickness * ( (real(k-1))/real(nz) -0.5 ) ! Stratification
      if (G%geolonh(i,j)-west_lon < 0.5 * len_lon) then
        eta1D(K)=eta1D(K) + 0.5 * front_displacement
      elseif (G%geolonh(i,j)-west_lon > 0.5 * len_lon) then
        eta1D(K)=eta1D(K) - 0.5 * front_displacement
      endif
    enddo
    eta1D(nz+1) = -max_depth ! Force bottom interface to bottom
    do k=nz,2,-1 ! Make sure interfaces increase upwards
      eta1D(K) = max( eta1D(K), eta1D(K+1) + G%Angstrom )
    enddo
    eta1D(1) = 0. ! Force bottom interface to bottom
    do k=2,nz ! Make sure interfaces decrease downwards
      eta1D(K) = min( eta1D(K), eta1D(K-1) - G%Angstrom )
    enddo
    do k=nz,1,-1
      h(i,j,k) = eta1D(K) - eta1D(K+1)
    enddo
  enddo ; enddo

end subroutine lock_exchange_initialize_thickness
! -----------------------------------------------------------------------------

end module lock_exchange_initialization
