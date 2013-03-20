module GOLD_constants

!********+*********+*********+*********+*********+*********+*********+**
!*                                                                     *
!*    This file is a part of GOLD.  See GOLD.F90 for licensing.        *
!*                                                                     *
!*    This module provides several constants.                          *
!*                                                                     *
!********+*********+*********+*********+*********+*********+*********+**

use constants_mod, only : HLV, HLF

implicit none ; private

real, public, parameter :: CELSIUS_KELVIN_OFFSET = 273.15
public :: HLV, HLF

end module GOLD_constants
