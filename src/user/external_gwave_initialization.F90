module external_gwave_initialization
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
!*  The module configures the model for the "external_gwave" experiment.         *
!*  external_gwave = Dense Overflow and Mixing Experiment?                       *
!*                                                                     *
!********+*********+*********+*********+*********+*********+*********+**

use GOLD_error_handler, only : GOLD_mesg, GOLD_error, FATAL, is_root_pe
use GOLD_file_parser, only : get_param, log_version, param_file_type
use GOLD_grid, only : ocean_grid_type
use GOLD_tracer, only : add_tracer_OBC_values, advect_tracer_CS
use GOLD_variables, only : thermo_var_ptrs, directories
implicit none ; private

#include <GOLD_memory.h>

public external_gwave_initialize_thickness

contains

! -----------------------------------------------------------------------------
subroutine external_gwave_initialize_thickness(h, G, param_file)
  real, intent(out), dimension(NXMEM_,NYMEM_, NZ_) :: h
  type(ocean_grid_type), intent(in) :: G
  type(param_file_type), intent(in) :: param_file
! Arguments: h - The thickness that is being initialized.
!  (in)      G - The ocean's grid structure.
!  (in)      param_file - A structure indicating the open file to parse for
!                         model parameter values.

!  This subroutine initializes layer thicknesses for the external_gwave experiment
  real :: e0(SZK_(G))     ! The resting interface heights, in m, usually !
                          ! negative because it is positive upward.      !
  real :: e_pert(SZK_(G)) ! Interface height perturbations, positive     !
                          ! upward, in m.                                !
  real :: eta1D(SZK_(G)+1)! Interface height relative to the sea surface !
                          ! positive upward, in m.                       !
  real :: max_depth  ! The minimum depth in m.
  real :: len_lon, west_lon ! Length of domain, position of western boundary
  real :: ssh_anomaly_height ! Vertical height of ssh anomaly
  real :: ssh_anomaly_width ! Lateral width of anomaly
  character(len=40)  :: mod = "external_gwave_initialize_thickness" ! This subroutine's name.
  integer :: i, j, k, is, ie, js, je, nz
  real :: PI, Xnondim

  is = G%isc ; ie = G%iec ; js = G%jsc ; je = G%jec ; nz = G%ke

  call GOLD_mesg("  external_gwave_initialization.F90, external_gwave_initialize_thickness: setting thickness", 5)

  call get_param(param_file, mod, "MAXIMUM_DEPTH", max_depth, &
                 "The maximum depth of the ocean.", units="m", &
                 fail_if_missing=.true.)
  call get_param(param_file, mod, "WESTLON", west_lon, &
                 "The western longitude of the domain.", units="degrees", &
                 default=0.0)
  call get_param(param_file, mod, "LENLON", len_lon, &
                 "The longitudinal length of the domain.", units="degrees", &
                 fail_if_missing=.true.)
  call get_param(param_file, mod, "SSH_ANOMALY_HEIGHT", ssh_anomaly_height, &
                 "The vertical displacement of the SSH anomaly. ", units="m", &
                 fail_if_missing=.true.)
  call get_param(param_file, mod, "SSH_ANOMALY_WIDTH", ssh_anomaly_width, &
                 "The lateral width of the SSH anomaly. ", units="coordinate", &
                 fail_if_missing=.true.)
  PI = 4.0*atan(1.0)
  do j=G%jsc,G%jec ; do i=G%isc,G%iec
    Xnondim = (G%geolonh(i,j)-west_lon-0.5*len_lon) / ssh_anomaly_width
    Xnondim = min(1., abs(Xnondim))
    eta1D(1) = ssh_anomaly_height * 0.5 * ( 1. + cos(PI*Xnondim) ) ! Cosine bell
    do k=2,nz
      eta1D(K) = -max_depth & ! Stretch interior interfaces with SSH
              + (eta1D(1)+max_depth) * ( real(nz+1-k)/real(nz) ) ! Stratification
    enddo
    eta1D(nz+1) = -max_depth ! Force bottom interface to bottom
    do k=1,nz
      h(i,j,k) = eta1D(K) - eta1D(K+1)
    enddo
  enddo ; enddo

end subroutine external_gwave_initialize_thickness
! -----------------------------------------------------------------------------

end module external_gwave_initialization
