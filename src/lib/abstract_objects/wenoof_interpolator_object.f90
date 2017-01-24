!< Abstract interpolator object.
module wenoof_interpolator_object
!< Abstract interpolator object.

use penf, only : I_P, R_P
use wenoof_base_object
use wenoof_interpolations_object
use wenoof_weights_object

implicit none
private
public :: interpolator_object
public :: interpolator_object_constructor

type, extends(base_object_constructor) :: interpolator_object_constructor
  !< Abstract interpolator object constructor.
  !<
  !< @note Every concrete WENO interpolator implementations must define their own constructor type.
  class(interpolations_object_constructor), allocatable :: interpolations_constructor !< Stencil interpolations constructor.
  class(weights_object_constructor),        allocatable :: weights_constructor        !< Weights of interpolations constructor.
endtype interpolator_object_constructor

type, extends(base_object), abstract :: interpolator_object
  !< Abstract interpolator object.
  !<
  !< @note Do not implement any actual interpolator: provide the interface for the different interpolators implemented.
  class(interpolations_object), allocatable :: interpolations !< Stencil interpolations.
  class(weights_object),        allocatable :: weights        !< Weights of interpolations.
  contains
    ! public deferred methods
    procedure(interpolate_debug_interface),    pass(self), deferred :: interpolate_debug    !< Interpolate values, debug mode.
    procedure(interpolate_standard_interface), pass(self), deferred :: interpolate_standard !< Interpolate values, standard mode.
    ! public methods
    generic :: interpolate => interpolate_standard, interpolate_debug !< Interpolate values.
endtype interpolator_object

abstract interface
  !< Abstract interfaces of [[interpolator_object]].
  pure subroutine interpolate_debug_interface(self, stencil, interpolation, si, weights)
  !< Interpolate values (providing also debug values).
  import :: interpolator_object, R_P
  class(interpolator_object), intent(inout) :: self                     !< Interpolator.
  real(R_P),                  intent(in)    :: stencil(1:, 1 - self%S:) !< Stencil of the interpolation [1:2, 1-S:-1+S].
  real(R_P),                  intent(out)   :: interpolation(1:)        !< Result of the interpolation, [1:2].
  real(R_P),                  intent(out)   :: si(1:, 0:)               !< Computed values of smoothness indicators [1:2, 0:S-1].
  real(R_P),                  intent(out)   :: weights(1:, 0:)          !< Weights of the stencils, [1:2, 0:S-1].
  endsubroutine interpolate_debug_interface

  pure subroutine interpolate_standard_interface(self, stencil, interpolation)
  !< Interpolate values (without providing debug values).
  import :: interpolator_object, R_P
  class(interpolator_object), intent(inout) :: self                     !< Interpolator.
  real(R_P),                  intent(in)    :: stencil(1:, 1 - self%S:) !< Stencil of the interpolation [1:2, 1-S:-1+S].
  real(R_P),                  intent(out)   :: interpolation(1:)        !< Result of the interpolation, [1:2].
  endsubroutine interpolate_standard_interface
endinterface

endmodule wenoof_interpolator_object
