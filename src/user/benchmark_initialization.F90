module benchmark_initialization
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
!*  The module configures the model for the "DOME" experiment.         *
!*  DOME = Dense Overflow and Mixing Experiment?                       *
!*                                                                     *
!********+*********+*********+*********+*********+*********+*********+**

use GOLD_sponge, only : sponge_CS, set_up_sponge_field, initialize_sponge
use GOLD_error_handler, only : GOLD_mesg, GOLD_error, FATAL, is_root_pe
use GOLD_file_parser, only : get_param, log_version, param_file_type
use GOLD_grid, only : ocean_grid_type
use GOLD_tracer, only : add_tracer_OBC_values, advect_tracer_CS
use GOLD_variables, only : thermo_var_ptrs, directories
use GOLD_variables, only : ocean_OBC_type, OBC_NONE, OBC_SIMPLE
use GOLD_EOS, only : calculate_density, calculate_density_derivs, EOS_type
implicit none ; private

#include <GOLD_memory.h>

public benchmark_initialize_topography
public benchmark_initialize_thickness
public benchmark_init_temperature_salinity

contains

! -----------------------------------------------------------------------------
subroutine benchmark_initialize_topography(D, G, param_file)
  real, intent(out), dimension(NXMEM_,NYMEM_) :: D
  type(ocean_grid_type), intent(in)           :: G
  type(param_file_type), intent(in)           :: param_file
! Arguments: D          - the bottom depth in m. Intent out.
!  (in)      G          - The ocean's grid structure.
!  (in)      param_file - A structure indicating the open file to parse for
!                         model parameter values.

! This subroutine sets up the benchmark test case topography
  real :: min_depth, max_depth ! The minimum and maximum depths in m.
  real :: PI                   ! 3.1415926... calculated as 4*atan(1)
  real :: D0                   ! A constant to make the maximum     !
                               ! basin depth MAXIMUM_DEPTH.         !
  real :: south_lat, west_lon, len_lon, len_lat, x, y
  character(len=128) :: version = '$Id$'
  character(len=128) :: tagname = '$Name$'
  character(len=40)  :: mod = "benchmark_initialize_topography" ! This subroutine's name.
  integer :: i, j, is, ie, js, je, isd, ied, jsd, jed
  is = G%isc ; ie = G%iec ; js = G%jsc ; je = G%jec
  isd = G%isd ; ied = G%ied ; jsd = G%jsd ; jed = G%jed

  call GOLD_mesg("  benchmark_initialization.F90, benchmark_initialize_topography: setting topography", 5)

  call log_version(param_file, mod, version, tagname, "")
  call get_param(param_file, mod, "MAXIMUM_DEPTH", max_depth, &
                 "The maximum depth of the ocean.", units="m", &
                 fail_if_missing=.true.)
  call get_param(param_file, mod, "MINIMUM_DEPTH", min_depth, &
                 "The minimum depth of the ocean.", units="m", default=0.0)
  call get_param(param_file, mod, "SOUTHLAT", south_lat, &
                 "The southern latitude of the domain or the equivalent \n"//&
                 "starting value for the y-axis.", units='degrees', default=0.0)
  call get_param(param_file, mod, "LENLAT", len_lat, &
                 "The latitudinal or y-direction length of the domain.", &
                 units='degrees', fail_if_missing=.true.)
  call get_param(param_file, mod, "WESTLON", west_lon, &
                 "The western longitude of the domain or the equivalent \n"//&
                 "starting value for the x-axis.", units='degrees', &
                 default=0.0)
  call get_param(param_file, mod, "LENLON", len_lon, &
                 "The longitudinal or x-direction length of the domain.", &
                 units='degrees', fail_if_missing=.true.)

  PI = 4.0*atan(1.0)
  D0 = max_depth / 0.5;

!  Calculate the depth of the bottom.
  do i=is,ie ; do j=js,je
    x=(G%geolonh(i,j)-west_lon)/len_lon
    y=(G%geolath(i,j)-south_lat)/len_lat
!  This sets topography that has a reentrant channel to the south.
    D(i,j) = -D0 * ( y*(1.0 + 0.6*cos(4.0*PI*x)) &
                   + 0.75*exp(-6.0*y) &
                   + 0.05*cos(10.0*PI*x) - 0.7 )
    if (D(i,j) > max_depth) D(i,j) = max_depth
    if (D(i,j) < min_depth) D(i,j) = 0.
  enddo ; enddo

end subroutine benchmark_initialize_topography
! -----------------------------------------------------------------------------

! -----------------------------------------------------------------------------
subroutine benchmark_initialize_thickness(h, G, param_file, eqn_of_state, P_ref)
  real, intent(out), dimension(NXMEM_,NYMEM_, NZ_) :: h
  type(ocean_grid_type), intent(in) :: G
  type(param_file_type), intent(in) :: param_file
  type(EOS_type),        pointer    :: eqn_of_state
  real,                                intent(in)  :: P_Ref
! Arguments: h - The thickness that is being initialized.
!  (in)      G - The ocean's grid structure.
!  (in)      param_file - A structure indicating the open file to parse for
!                         model parameter values.
!  (in)      eqn_of_state - integer that selects the equatio of state
!  (in)      P_Ref - The coordinate-density reference pressure in Pa.

!   This subroutine initializes layer thicknesses for the benchmark test case,
! by finding the depths of interfaces in a specified latitude-dependent
! temperature profile with an exponentially decaying thermocline on top of a
! linear stratification.
  real :: e0(SZK_(G)+1)     ! The resting interface heights, in m, usually !
                            ! negative because it is positive upward.      !
  real :: e_pert(SZK_(G)+1) ! Interface height perturbations, positive     !
                            ! upward, in m.                                !
  real :: eta1D(SZK_(G)+1)  ! Interface height relative to the sea surface !
                            ! positive upward, in m.                       !
  real :: SST       !  The initial sea surface temperature, in deg C.
  real :: T_int     !  The initial temperature of an interface, in deg C.
  real :: ML_depth  !  The specified initial mixed layer depth, in m.
  real :: thermocline_scale ! The e-folding scale of the thermocline, in m.
  real, dimension(SZK_(G)) :: T0, pres, S0, rho_guess, drho, drho_dT, drho_dS
  real :: max_depth  ! The maximum ocean depth in m.
  real :: a_exp      ! The fraction of the overall stratification that is exponential.
  real :: I_ts, I_md ! Inverse lengthscales in m-1.
  real :: T_frac     ! A ratio of the interface temperature to the range
                     ! between SST and the bottom temperature.
  real :: err, derr_dz  ! The error between the profile's temperature and the
                     ! interface temperature for a given z and its derivative.
  real :: south_lat, west_lon, len_lon, len_lat, pi, z
  character(len=40)  :: mod = "benchmark_initialize_thickness" ! This subroutine's name.
  logical :: bulkmixedlayer
  integer :: i, j, k, k1, is, ie, js, je, nz, itt

  is = G%isc ; ie = G%iec ; js = G%jsc ; je = G%jec ; nz = G%ke

  call GOLD_mesg("  benchmark_initialization.F90, benchmark_initialize_thickness: setting thickness", 5)

  k1 = G%nk_rho_varies + 1

  call get_param(param_file, mod, "MAXIMUM_DEPTH", max_depth, &
                 "The maximum depth of the ocean.", units="m", &
                 fail_if_missing=.true.)
  call get_param(param_file, mod, "SOUTHLAT", south_lat, &
                 "The southern latitude of the domain or the equivalent \n"//&
                 "starting value for the y-axis.", units='degrees', default=0.0)
  call get_param(param_file, mod, "LENLAT", len_lat, &
                 "The latitudinal or y-direction length of the domain.", &
                 units='degrees', fail_if_missing=.true.)
  call get_param(param_file, mod, "WESTLON", west_lon, &
                 "The western longitude of the domain or the equivalent \n"//&
                 "starting value for the x-axis.", units='degrees', &
                 default=0.0)
  call get_param(param_file, mod, "LENLON", len_lon, &
                 "The longitudinal or x-direction length of the domain.", &
                 units='degrees', fail_if_missing=.true.)

  ML_depth = 50.0
  thermocline_scale = 500.0
  a_exp = 0.9

! This block calculates T0(k) for the purpose of diagnosing where the 
! interfaces will be found.
  do k=1,nz
    pres(k) = P_Ref ; S0(k) = 35.0
  enddo
  T0(k1) = 29.0
  call calculate_density(T0(k1),S0(k1),pres(k1),rho_guess(k1),1,1,eqn_of_state)
  call calculate_density_derivs(T0,S0,pres,drho_dT,drho_dS,k1,1,eqn_of_state)

! A first guess of the layers' temperatures.
  do k=1,nz
    T0(k) = T0(k1) + (G%Rlay(k) - rho_guess(k1)) / drho_dT(k1)
  enddo

! Refine the guesses for each layer.
  do itt=1,6
    call calculate_density(T0,S0,pres,rho_guess,1,nz,eqn_of_state)
    call calculate_density_derivs(T0,S0,pres,drho_dT,drho_dS,1,nz,eqn_of_state)
    do k=1,nz
      T0(k) = T0(k) + (G%Rlay(k) - rho_guess(k)) / drho_dT(k)
    enddo
  enddo

  pi = 4.0*atan(1.0)
  I_ts = 1.0 / thermocline_scale
  I_md = 1.0 / max_depth
  do j=js,je ; do i=is,ie
    SST = 0.5*(T0(k1)+T0(nz)) - 0.9*0.5*(T0(k1)-T0(nz)) * &
                               cos(pi*(G%geolath(i,j)-south_lat)/(len_lat))

    do k=1,nz ; e_pert(K) = 0.0 ; enddo

!  The remainder of this subroutine should not be changed.           !

!    This sets the initial thickness (in m) of the layers.  The      !
!  thicknesses are set to insure that: 1.  each layer is at least    !
!  G%Angstrom_z thick, and 2.  the interfaces are where they should be    !
!  based on the resting depths and interface height perturbations,   !
!  as long at this doesn't interfere with 1.                         !
    eta1D(nz+1) = -1.0*G%D(i,j)

    do k=nz,2,-1
      T_int = 0.5*(T0(k) + T0(k-1))
      T_frac = (T_int - T0(nz)) / (SST - T0(nz))
      ! Find the z such that T_frac = a exp(z/thermocline_scale) + (1-a) (z+D)/D
      z = 0.0
      do itt=1,6
        err = a_exp * exp(z*I_ts) + (1.0 - a_exp) * (z*I_md + 1.0) - T_frac
        derr_dz = a_exp * I_ts * exp(z*I_ts) + (1.0 - a_exp) * I_md
        z = z - err / derr_dz
      enddo
      e0(K) = z
!       e0(K) = -ML_depth + thermocline_scale * log((T_int - T0(nz)) / (SST - T0(nz)))

      eta1D(K) = e0(K) + e_pert(K)

      if (eta1D(K) > -ML_depth) eta1D(K) = -ML_depth

      if (eta1D(K) < eta1D(K+1) + G%Angstrom_z) &
        eta1D(K) = eta1D(K+1) + G%Angstrom_z

      h(i,j,k) = max(eta1D(K) - eta1D(K+1), G%Angstrom_z)
    enddo
    h(i,j,1) = max(0.0 - eta1D(2), G%Angstrom_z)

  enddo ; enddo

end subroutine benchmark_initialize_thickness
! -----------------------------------------------------------------------------

! -----------------------------------------------------------------------------
subroutine benchmark_init_temperature_salinity(T, S, G, param_file, &
               eqn_of_state, P_Ref)
  real, dimension(NXMEM_,NYMEM_, NZ_), intent(out) :: T, S
  type(ocean_grid_type),               intent(in)  :: G
  type(param_file_type),               intent(in)  :: param_file
  type(EOS_type),                      pointer     :: eqn_of_state
  real,                                intent(in)  :: P_Ref
!  This function puts the initial layer temperatures and salinities  !
! into T(:,:,:) and S(:,:,:).                                        !

! Arguments: T - The potential temperature that is being initialized.
!  (out)     S - The salinity that is being initialized.
!  (in)      G - The ocean's grid structure.
!  (in)      param_file - A structure indicating the open file to parse for
!                         model parameter values.
!  (in)      eqn_of_state - integer that selects the equatio of state
!  (in)      P_Ref - The coordinate-density reference pressure in Pa.
  real :: T0(SZK_(G)), S0(SZK_(G))
  real :: pres(SZK_(G))      ! Reference pressure in kg m-3.             !
  real :: drho_dT(SZK_(G))   ! Derivative of density with temperature in !
                        ! kg m-3 K-1.                               !
  real :: drho_dS(SZK_(G))   ! Derivative of density with salinity in    !
                        ! kg m-3 PSU-1.                             !
  real :: rho_guess(SZK_(G)) ! Potential density at T0 & S0 in kg m-3.   !
  real :: PI        ! 3.1415926... calculated as 4*atan(1)
  real :: SST       !  The initial sea surface temperature, in deg C.
  real :: lat, len_lat, south_lat
  character(len=40)  :: mod = "benchmark_init_temperature_salinity" ! This subroutine's name.
  logical :: bulkmixedlayer
  integer :: i, j, k, k1, is, ie, js, je, nz, itt

  is = G%isc ; ie = G%iec ; js = G%jsc ; je = G%jec ; nz = G%ke

  call get_param(param_file, mod, "SOUTHLAT", south_lat, &
                 "The southern latitude of the domain or the equivalent \n"//&
                 "starting value for the y-axis.", units='degrees', default=0.0)
  call get_param(param_file, mod, "LENLAT", len_lat, &
                 "The latitudinal or y-direction length of the domain.", &
                 units='degrees', fail_if_missing=.true.)

  k1 = G%nk_rho_varies + 1

  do k=1,nz
    pres(k) = P_Ref ; S0(k) = 35.0
  enddo

  T0(k1) = 29.0
  call calculate_density(T0(k1),S0(k1),pres(k1),rho_guess(k1),1,1,eqn_of_state)
  call calculate_density_derivs(T0,S0,pres,drho_dT,drho_dS,k1,1,eqn_of_state)

! A first guess of the layers' temperatures.                         !
  do k=1,nz
    T0(k) = T0(k1) + (G%Rlay(k) - rho_guess(k1)) / drho_dT(k1)
  enddo

! Refine the guesses for each layer.                                 !
  do itt = 1,6
    call calculate_density(T0,S0,pres,rho_guess,1,nz,eqn_of_state)
    call calculate_density_derivs(T0,S0,pres,drho_dT,drho_dS,1,nz,eqn_of_state)
    do k=1,nz
      T0(k) = T0(k) + (G%Rlay(k) - rho_guess(k)) / drho_dT(k)
    enddo
  enddo

  do k=1,nz ; do i=is,ie ; do j=js,je
    T(i,j,k) = T0(k)
    S(i,j,k) = S0(k)
  enddo ; enddo ; enddo
  PI = 4.0*atan(1.0)
  do i=is,ie ; do j=js,je
    SST = 0.5*(T0(k1)+T0(nz)) - 0.9*0.5*(T0(k1)-T0(nz)) * &
                               cos(PI*(G%geolath(i,j)-south_lat)/(len_lat))
    do k=1,k1-1
      T(i,j,k) = SST
    enddo
  enddo ; enddo

end subroutine benchmark_init_temperature_salinity
! -----------------------------------------------------------------------------

end module benchmark_initialization
