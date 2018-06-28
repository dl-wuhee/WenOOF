!< Jiang-Shu and Gerolymos-Senechal-Vallet Beta coefficients (smoothness indicators of stencil interpolations) object.
module wenoof_beta_int_js
!< Jiang-Shu and Gerolymos-Senechal-Vallet Beta coefficients (smoothness indicators of stencil interpolations) object.
!<
!< @note The provided interpolations implement the Lagrange interpolations defined in *High Order Weighted Essentially
!< Nonoscillatory Schemes for Convection Dominated Problems*, Chi-Wang Shu, SIAM Review, 2009, vol. 51, pp. 82--126,
!< doi:10.1137/070679065.

use penf, only : I_P, R_P, str
use wenoof_base_object, only : base_object, base_object_constructor
use wenoof_beta_object, only : beta_object, beta_object_constructor

implicit none
private
public :: beta_int_js
public :: beta_int_js_constructor

type, extends(beta_object_constructor) :: beta_int_js_constructor
  !< Jiang-Shu and Gerolymos-Senechal-Vallet beta object constructor.
  contains
    ! public deferred methods
    procedure, pass(lhs) :: constr_assign_constr !< `=` operator.
endtype beta_int_js_constructor

type, extends(beta_object) :: beta_int_js
  !< Jiang-Shu and Gerolymos-Senechal-Vallet Beta coefficients (smoothness indicators of stencil interpolations) object.
  !<
  !< @note The provided interpolations implement the Lagrange interpolations defined in *High Order Weighted Essentially
  !< Nonoscillatory Schemes for Convection Dominated Problems*, Chi-Wang Shu, SIAM Review, 2009, vol. 51, pp. 82--126,
  !< doi:10.1137/070679065.
  private
  real(R_P), allocatable :: coef(:,:,:,:) !< Beta coefficients [0:S-1,0:S-1,0:S-1,2:S].
  contains
    ! public deferred methods
    procedure, pass(self) :: create               !< Create beta.
    procedure, pass(self) :: compute_int          !< Compute beta (interpolate).
    procedure, pass(self) :: compute_rec          !< Compute beta (reconstruct).
    procedure, pass(self) :: description          !< Return object string-description.
    procedure, pass(self) :: destroy              !< Destroy beta.
    procedure, pass(lhs)  :: object_assign_object !< `=` operator.
endtype beta_int_js

contains
  ! constructor

  ! deferred public methods
  subroutine constr_assign_constr(lhs, rhs)
  !< `=` operator.
  class(beta_int_js_constructor), intent(inout) :: lhs !< Left hand side.
  class(base_object_constructor), intent(in)    :: rhs !< Right hand side.

  call lhs%assign_(rhs=rhs)
  endsubroutine constr_assign_constr

  ! public deferred methods
  subroutine create(self, constructor)
  !< Create beta.
  class(beta_int_js),              intent(inout) :: self        !< Beta.
  class(base_object_constructor),  intent(in)    :: constructor !< Beta constructor.
  integer(I_P)                                   :: i           !< Counter.

  call self%destroy
  call self%create_(constructor=constructor)
  if (self%ror) then
    allocate(self%coef(0:self%S - 1, 0:self%S - 1, 0:self%S - 1, 2:self%S))
    do i=2, self%S
      call assign_beta_coeff(c=self%coef(:,:,:,i), i=i)
    enddo
  else
    allocate(self%coef(0:self%S - 1, 0:self%S - 1, 0:self%S - 1 ,1))
    call assign_beta_coeff(c=self%coef(:,:,:,1), i=self%S)
  endif
  endsubroutine create

  pure subroutine compute_int(self, ord, stencil, values)
  !< Compute beta (interpolate).
  class(beta_int_js), intent(in)  :: self            !< Beta.
  integer(I_P),       intent(in)  :: ord             !< Order of interpolation.
  real(R_P),          intent(in)  :: stencil(1-ord:) !< Stencil used for the interpolation, [1-S:-1+S].
  real(R_P),          intent(out) :: values(0:)      !< Beta values [0:S-1].
  integer(I_P)                    :: s1, s2, s3      !< Counters.

  do s1=0, ord - 1 ! stencils loop
    values(s1) = 0._R_P
    do s2=0, ord - 1
      do s3=0, ord - 1
        values(s1) = values(s1) + self%coef(s3, s2, s1, ord) * stencil(s1 - s3) * stencil(s1 - s2)
      enddo
    enddo
  enddo
  endsubroutine compute_int

  pure subroutine compute_rec(self, ord, stencil, values)
  !< Compute beta (reconstruct).
  class(beta_int_js), intent(in)  :: self               !< Beta.
  integer(I_P),       intent(in)  :: ord                !< Order of interpolation.
  real(R_P),          intent(in)  :: stencil(1:,1-ord:) !< Stencil used for the interpolation, [1:2, 1-S:-1+S].
  real(R_P),          intent(out) :: values(1:,0:)      !< Beta values [1:2,0:S-1].
  ! empty procedure
  endsubroutine compute_rec

  pure function description(self, prefix) result(string)
  !< Return object string-descripition.
  class(beta_int_js), intent(in)           :: self             !< Beta coefficient.
  character(len=*),   intent(in), optional :: prefix           !< Prefixing string.
  character(len=:), allocatable            :: string           !< String-description.
  character(len=:), allocatable            :: prefix_          !< Prefixing string, local variable.
  character(len=1), parameter              :: NL=new_line('a') !< New line char.

  prefix_ = '' ; if (present(prefix)) prefix_ = prefix
  string = prefix_//'Jiang-Shu beta coefficients object for interpolation:'//NL
  string = string//prefix_//'  - S   = '//trim(str(self%S))
  endfunction description

  elemental subroutine destroy(self)
  !< Destroy beta.
  class(beta_int_js), intent(inout) :: self !< Beta.

  call self%destroy_
  if (allocated(self%coef)) deallocate(self%coef)
  endsubroutine destroy

  pure subroutine object_assign_object(lhs, rhs)
  !< `=` operator.
  class(beta_int_js), intent(inout) :: lhs !< Left hand side.
  class(base_object), intent(in)    :: rhs !< Right hand side.

  call lhs%assign_(rhs=rhs)
  select type(rhs)
  type is(beta_int_js)
     if (allocated(rhs%coef)) then
        lhs%coef = rhs%coef
     else
        if (allocated(lhs%coef)) deallocate(lhs%coef)
     endif
  endselect
  endsubroutine object_assign_object

  ! private non TBP
  pure subroutine assign_beta_coeff(c, i)
  !< Assign the value of beta coefficients.
  real(R_P),    intent(inout) :: c(0:,0:,0:) !< Beta values.
  integer(I_P), intent(in)    :: i           !< Counter.

  select case(i)
  case(2) ! 3rd order
    ! stencil 0
    !       i*i      ;     (i-1)*i
    c(0,0,0) = 1._R_P; c(1,0,0) = -2._R_P
    !      /         ;     (i-1)*(i-1)
    c(0,1,0) = 0._R_P; c(1,1,0) =  1._R_P
    ! stencil 1
    !  (i+1)*(i+1)   ;     (i+1)*i
    c(0,0,1) = 1._R_P; c(1,0,1) = -2._R_P
    !      /         ;      i*i
    c(0,1,1) = 0._R_P; c(1,1,1) =  1._R_P
  case(3) ! 5th order
    ! stencil 0
    !      i*i                ;       (i-1)*i             ;       (i-2)*i
    c(0,0,0) =  10._R_P/3._R_P; c(1,0,0) = -31._R_P/3._R_P; c(2,0,0) =  11._R_P/3._R_P
    !      /                  ;       (i-1)*(i-1)         ;       (i-2)*(i-1)
    c(0,1,0) =   0._R_P       ; c(1,1,0) =  25._R_P/3._R_P; c(2,1,0) = -19._R_P/3._R_P
    !      /                  ;        /                  ;       (i-2)*(i-2)
    c(0,2,0) =   0._R_P       ; c(1,2,0) =   0._R_P       ; c(2,2,0) =   4._R_P/3._R_P
    ! stencil 1
    !     (i+1)*(i+1)         ;        i*(i+1)            ;       (i-1)*(i+1)
    c(0,0,1) =   4._R_P/3._R_P; c(1,0,1) = -13._R_P/3._R_P; c(2,0,1) =   5._R_P/3._R_P
    !      /                  ;        i*i                ;       (i-1)*i
    c(0,1,1) =   0._R_P       ; c(1,1,1) =  13._R_P/3._R_P; c(2,1,1) = -13._R_P/3._R_P
    !      /                  ;        /                  ;       (i-1)*(i-1)
    c(0,2,1) =   0._R_P       ; c(1,2,1) =   0._R_P       ; c(2,2,1) =   4._R_P/3._R_P
    ! stencil 2
    !     (i+2)*(i+2)         ;       (i+1)*(i+2)         ;        i*(i+2)
    c(0,0,2) =   4._R_P/3._R_P; c(1,0,2) = -19._R_P/3._R_P; c(2,0,2) =  11._R_P/3._R_P
    !      /                  ;       (i+1)*(i+1)         ;        i*(i+1)
    c(0,1,2) =   0._R_P       ; c(1,1,2) =  25._R_P/3._R_P; c(2,1,2) = -31._R_P/3._R_P
    !      /                  ;        /                  ;        i*i
    c(0,2,2) =   0._R_P       ; c(1,2,2) =   0._R_P       ; c(2,2,2) =  10._R_P/3._R_P
  case(4) ! 7th order
    ! stencil 0
    !              i*i               ;             (i-1)*i              ;            (i-2)*i
    c(0,0,0) = 25729._R_P / 2880._R_P; c(1,0,0) = -6383._R_P /  160._R_P; c(2,0,0) = 14369._R_P / 480._R_P
    !          (i-3)*i
    c(3,0,0) =-11389._R_P / 1440._R_P
    !               /                ;            (i-1)*(i-1)           ;            (i-2)*(i-1)
    c(0,1,0) =     0._R_P            ; c(1,1,0) = 44747._R_P /  960._R_P; c(2,1,0) =-35047._R_P / 480._R_P
    !          (i-3)*(i-1)
    c(3,1,0) =  9449._R_P /  480._R_P
    !               /                ;                 /                ;            (i-2)*(i-2)
    c(0,2,0) =     0._R_P            ; c(1,2,0) =     0._R_P            ; c(2,2,0) = 28547._R_P / 960._R_P
    !          (i-3)*(i-2)
    c(3,2,0) = -2623._R_P /  160._R_P
    !                /               ;                 /                ;                 /
    c(0,3,0) =     0._R_P            ; c(1,3,0) =     0._R_P            ; c(2,3,0) =     0._R_P
    !          (i-3)*(i-3)
    c(3,3,0) =  6649._R_P / 2880._R_P
    ! stencil 1
    !          (i+1)*(i+1)           ;                i*(i+1)           ;            (i-1)*(i+1)
    c(0,0,1) =  6649._R_P / 2880._R_P; c(1,0,1) = -5069._R_P /  480._R_P; c(2,0,1) =  1283._R_P / 160._R_P
    !          (i-2)*(i+1)
    c(3,0,1) = -2989._R_P / 1440._R_P
    !               /                ;                i*i               ;            (i-1)*i
    c(0,1,1) =     0._R_P            ; c(1,1,1) = 13667._R_P /  960._R_P; c(2,1,1) =-11767._R_P / 480._R_P
    !          (i-2)*i
    c(3,1,1) =  3169._R_P /  480._R_P
    !               /                ;                 /                ;            (i-1)*(i-1)
    c(0,2,1) =     0._R_P            ; c(1,2,1) =     0._R_P            ; c(2,2,1) = 11147._R_P / 960._R_P
    !          (i-2)*(i-1)
    c(3,2,1) = -3229._R_P /  480._R_P
    !               /                ;                 /                ;                 /
    c(0,3,1) =     0._R_P            ; c(1,3,1) =     0._R_P            ; c(2,3,1) =     0._R_P
    !          (i-2)*(i-2)
    c(3,3,1) =  3169._R_P / 2880._R_P
    ! stencil 2
    !          (i+2)*(i+2)           ;            (i+1)*(i+2)           ;                i*(i+2)
    c(0,0,2) =  3169._R_P / 2880._R_P; c(1,0,2) = -3229._R_P /  480._R_P; c(2,0,2) =  3169._R_P / 480._R_P
    !          (i-1)*(i+2)
    c(3,0,2) = -2989._R_P / 1440._R_P
    !               /                ;            (i+1)*(i+1)           ;                i*(i+1)
    c(0,1,2) =     0._R_P            ; c(1,1,2) = 11147._R_P /  960._R_P; c(2,1,2) =-11767._R_P / 480._R_P
    !          (i-1)*(i+1)
    c(3,1,2) =  1283._R_P /  160._R_P
    !               /                ;                 /                ;                i*i
    c(0,2,2) =     0._R_P            ; c(1,2,2) =     0._R_P            ; c(2,2,2) = 13667._R_P / 960._R_P
    !          (i-1)*i
    c(3,2,2) = -5069._R_P /  480._R_P
    !               /                ;                 /                ;                 /
    c(0,3,2) =     0._R_P            ; c(1,3,2) =     0._R_P            ; c(2,3,2) =     0._R_P
    !          (i-1)*(i-1)
    c(3,3,2) =  6649._R_P / 2880._R_P
    ! stencil 3
    !          (i+3)*(i+3)           ;            (i+2)*(i+3)           ;            (i+1)*(i+3)
    c(0,0,3) =  6649._R_P / 2880._R_P; c(1,0,3) = -2623._R_P /  160._R_P; c(2,0,3) =  9449._R_P / 480._R_P
    !              i*(i+3)
    c(3,0,3) =-11389._R_P / 1440._R_P
    !               /                ;            (i+2)*(i+2)           ;      (i+1)*(i+2)
    c(0,1,3) =     0._R_P            ; c(1,1,3) = 28547._R_P /  960._R_P; c(2,1,3) =-35047._R_P / 480._R_P
    !              i*(i+2)
    c(3,1,3) = 14369._R_P /  480._R_P
    !               /                ;                 /                ;      (i+1)*(i+1)
    c(0,2,3) =     0._R_P            ; c(1,2,3) =     0._R_P            ; c(2,2,3) = 44747._R_P / 960._R_P
    !              i*(i+1)
    c(3,2,3) = -6383._R_P /  160._R_P
    !               /               ;                 /               ;           /
    c(0,3,3) =     0._R_P           ; c(1,3,3) =     0._R_P           ; c(2,3,3) =     0._R_P
    !              i*i
    c(3,3,3) = 25729._R_P / 2880._R_P
  case(5) ! 9th order
    ! stencil 0
    !               i*i                  ;              (i-1)*i                 ;             (i-2)*i
    c(0,0,0) =   668977._R_P / 30240._R_P; c(1,0,0) = -8055511._R_P / 60480._R_P; c(2,0,0) = 3141559._R_P / 20160._R_P
    !           (i-3)*i                  ;              (i-4)*i
    c(3,0,0) = -5121853._R_P / 60480._R_P; c(4,0,0) =  1076779._R_P / 60480._R_P
    !                /                   ;              (i-1)*(i-1)             ;             (i-2)*(i-1)
    c(0,1,0) =        0._R_P             ; c(1,1,0) = 12627689._R_P / 60480._R_P; c(2,1,0) =-2536843._R_P /  5040._R_P
    !           (i-3)*(i-1)              ;             (i-4)*(i-1)
    c(3,1,0) =  8405471._R_P / 30240._R_P; c(4,1,0) = -3568693._R_P / 60480._R_P
    !                /                   ;                  /                   ;             (i-2)*(i-2)
    c(0,2,0) =        0._R_P             ; c(1,2,0) =        0._R_P             ; c(2,2,0) = 2085371._R_P /  6720._R_P
    !           (i-3)*(i-2)              ;             (i-4)*(i-2)
    c(3,2,0) = -1751863._R_P /  5040._R_P; c(4,2,0) =  1501039._R_P / 20160._R_P
    !                /                   ;                  /                   ;                  /
    c(0,3,0) =        0._R_P             ; c(1,3,0) =        0._R_P             ; c(2,3,0) =       0._R_P
    !           (i-3)*(i-3)              ;             (i-4)*(i-3)
    c(3,3,0) =  5951369._R_P / 60480._R_P; c(4,3,0) = -2569471._R_P / 60480._R_P
    !                /                   ;                  /                   ;                  /
    c(0,4,0) =        0._R_P             ; c(1,4,0) =        0._R_P             ; c(2,4,0) =       0._R_P
    !                /                   ;             (i-4)*(i-4)
    c(3,4,0) =        0._R_P             ; c(4,4,0) =   139567._R_P / 30240._R_P
    ! stencil 1
    !           (i+1)*(i+1)              ;                 i*(i+1)              ;             (i-1)*(i+1)
    c(0,0,1) =   139567._R_P / 30240._R_P; c(1,0,1) = -1714561._R_P / 60480._R_P; c(2,0,1) =  671329._R_P / 20160._R_P
    !           (i-2)*(i+1)              ;             (i-3)*(i+1)
    c(3,0,1) = -1079563._R_P / 60480._R_P; c(4,0,1) =   221869._R_P / 60480._R_P
    !                /                   ;                 i*i                  ;             (i-1)*i
    c(0,1,1) =        0._R_P             ; c(1,1,1) =  2932409._R_P / 60480._R_P; c(2,1,1) = -306569._R_P /  2520._R_P
    !           (i-2)*i                  ;             (i-3)*i
    c(3,1,1) =  2027351._R_P / 30240._R_P; c(4,1,1) =  -847303._R_P / 60480._R_P
    !                /                   ;                  /                   ;             (i-1)*(i-1)
    c(0,2,1) =        0._R_P             ; c(1,2,1) =        0._R_P             ; c(2,2,1) =  539351._R_P /  6720._R_P
    !           (i-2)*(i-1)              ;             (i-3)*(i-1)
    c(3,2,1) =   -57821._R_P /   630._R_P; c(4,2,1) =   395389._R_P / 20160._R_P
    !                /                   ;                  /                   ;                  /
    c(0,3,1) =        0._R_P             ; c(1,3,1) =        0._R_P             ; c(2,3,1) =       0._R_P
    !           (i-2)*(i-2)              ;             (i-3)*(i-2)
    c(3,3,1) =  1650569._R_P / 60480._R_P; c(4,3,1) =  -725461._R_P / 60480._R_P
    !                /                   ;                  /                   ;                  /
    c(0,4,1) =        0._R_P             ; c(1,4,1) =        0._R_P             ; c(2,4,1) =       0._R_P
    !                /                   ;             (i-3)*(i-3)
    c(3,4,1) =        0._R_P             ; c(4,4,1) =    20591._R_P / 15120._R_P
    ! stencil 2
    !           (i+2)*(i+2)              ;             (i+1)*(i+2)              ;                 i*(i+2)
    c(0,0,2) =    20591._R_P / 15120._R_P; c(1,0,2) =  -601771._R_P / 60480._R_P; c(2,0,2) =  266659._R_P /  20160._R_P
    !           (i-1)*(i+2)              ;             (i-2)*(i+2)
    c(3,0,2) =  -461113._R_P / 60480._R_P; c(4,0,2) =    98179._R_P / 60480._R_P
    !                /                   ;             (i+1)*(i+1)              ;                 i*(i+1)
    c(0,1,2) =        0._R_P             ; c(1,1,2) =  1228889._R_P / 60480._R_P; c(2,1,2) = -291313._R_P /   5040._R_P
    !           (i-1)*(i+1)              ;             (i-2)*(i+1)
    c(3,1,2) =  1050431._R_P / 30240._R_P; c(4,1,2) =  -461113._R_P / 60480._R_P
    !                /                   ;                  /                   ;                 i*i
    c(0,2,2) =        0._R_P             ; c(1,2,2) =        0._R_P             ; c(2,2,2) =   299531._R_P / 6720._R_P
    !           (i-1)*i                  ;             (i-2)*i
    c(3,2,2) =  -291313._R_P /  5040._R_P; c(4,2,2) =   266659._R_P / 20160._R_P
    !                /                   ;                  /                   ;                  /
    c(0,3,2) =        0._R_P             ; c(1,3,2) =        0._R_P             ; c(2,3,2) =       0._R_P
    !           (i-1)*(i-1)              ;             (i-2)*(i-1)
    c(3,3,2) =  1228889._R_P / 60480._R_P; c(4,3,2) =  -601771._R_P / 60480._R_P
    !                /                   ;                  /                   ;                  /
    c(0,4,2) =        0._R_P             ; c(1,4,2) =        0._R_P             ; c(2,4,2) =       0._R_P
    !                /                   ;             (i-2)*(i-2)
    c(3,4,2) =        0._R_P             ; c(4,4,2) =    20591._R_P / 15120._R_P
    ! stencil 3
    !           (i+3)*(i+3)              ;             (i+2)*(i+3)              ;             (i+1)*(i+3)
    c(0,0,3) =    20591._R_P / 15120._R_P; c(1,0,3) =  -725461._R_P / 60480._R_P; c(2,0,3) =  395389._R_P / 20160._R_P
    !               i*(i+3)              ;             (i-1)*(i+3)
    c(3,0,3) =  -847303._R_P / 60480._R_P; c(4,0,3) =   221869._R_P / 60480._R_P
    !                /                   ;             (i+2)*(i+2)              ;             (i+1)*(i+2)
    c(0,1,3) =        0._R_P             ; c(1,1,3) =  1650569._R_P / 60480._R_P; c(2,1,3) =  -57821._R_P /   630._R_P
    !               i*(i+2)              ;             (i-1)*(i+2)
    c(3,1,3) =  2027351._R_P / 30240._R_P; c(4,1,3) = -1079563._R_P / 60480._R_P
    !                /                   ;                  /                   ;             (i+1)*(i+1)
    c(0,2,3) =        0._R_P             ; c(1,2,3) =        0._R_P             ; c(2,2,3) =  539351._R_P /  6720._R_P
    !               i*(i+1)              ;             (i-1)*(i+1)
    c(3,2,3) =  -306569._R_P /  2520._R_P; c(4,2,3) =   671329._R_P / 20160._R_P
    !                /                   ;                  /                   ;                  /
    c(0,3,3) =        0._R_P             ; c(1,3,3) =        0._R_P             ; c(2,3,3) =       0._R_P
    !               i*i                  ;             (i-1)*i
    c(3,3,3) =  2932409._R_P / 60480._R_P; c(4,3,3) = -1714561._R_P / 60480._R_P
    !                /                   ;                  /                   ;                  /
    c(0,4,3) =        0._R_P             ; c(1,4,3) =        0._R_P             ; c(2,4,3) =       0._R_P
    !                /                   ;             (i-1)*(i-1)
    c(3,4,3) =        0._R_P             ; c(4,4,3) =   139567._R_P / 30240._R_P
    ! stencil 4
    !           (i+4)*(i+4)              ;             (i+3)*(i+4)              ;             (i+2)*(i+4)
    c(0,0,4) =   139567._R_P / 30240._R_P; c(1,0,4) = -2569471._R_P / 60480._R_P; c(2,0,4) = 1501039._R_P / 20160._R_P
    !           (i+1)*(i+4)              ;                 i*(i+4)
    c(3,0,4) = -3568693._R_P / 60480._R_P; c(4,0,4) =  1076779._R_P / 60480._R_P
    !                /                   ;             (i+3)*(i+3)              ;             (i+2)*(i+3)
    c(0,1,4) =        0._R_P             ; c(1,1,4) =  5951369._R_P / 60480._R_P; c(2,1,4) =-1751863._R_P /  5040._R_P
    !           (i+1)*(i+3)              ;                 i*(i+3)
    c(3,1,4) =  8405471._R_P / 30240._R_P; c(4,1,4) = -5121853._R_P / 60480._R_P
    !                /                   ;                  /                   ;             (i+2)*(i+2)
    c(0,2,4) =        0._R_P             ; c(1,2,4) =        0._R_P             ; c(2,2,4) = 2085371._R_P /  6720._R_P
    !           (i+1)*(i+2)              ;                 i*(i+2)
    c(3,2,4) = -2536843._R_P /  5040._R_P; c(4,2,4) =  3141559._R_P / 20160._R_P
    !                /                   ;                  /                   ;                  /
    c(0,3,4) =        0._R_P             ; c(1,3,4) =        0._R_P             ; c(2,3,4) =       0._R_P
    !           (i+1)*(i+1)              ;                 i*(i+1)
    c(3,3,4) = 12627689._R_P / 60480._R_P; c(4,3,4) = -8055511._R_P / 60480._R_P
    !                /                   ;                  /                   ;                  /
    c(0,4,4) =        0._R_P             ; c(1,4,4) =        0._R_P             ; c(2,4,4) =       0._R_P
    !                /                   ;                 i*i
    c(3,4,4) =        0._R_P             ; c(4,4,4) =   668977._R_P / 30240._R_P
  case(6) ! 11th order
    ! stencil 0
    !                  i*i                 ;                (i-1)*i                  ;                 (i-2)*i
    c(0,0,0) = 373189088._R_P/ 7027375._R_P; c(1,0,0) = -157371280._R_P/  384113._R_P; c(2,0,0) =  497902688._R_P/  756325._R_P
    !              (i-3)*i                 ;                (i-4)*i                  ;                (i-5)*i
    c(3,0,0) =-427867945._R_P/  780329._R_P; c(4,0,0) =  295095211._R_P/ 1259192._R_P; c(5,0,0) = -131759526._R_P/ 3224383._R_P

    !                  /                   ;                (i-1)*(i-1)              ;                (i-2)*(i-1)
    c(0,1,0) =         0._R_P              ; c(1,1,0) =  498196769._R_P/  609968._R_P; c(2,1,0) = -497421494._R_P/  185427._R_P
    !             (i-3)*(i-1)              ;                (i-4)*(i-1)              ;                (i-5)*(i-1)
    c(3,1,0) =1150428332._R_P/  508385._R_P; c(4,1,0) = -674462631._R_P/  691651._R_P; c(5,1,0) =  112453613._R_P/  657635._R_P

    !                  /                   ;                     /                   ;                (i-2)*(i-2)
    c(0,2,0) =         0._R_P              ; c(1,2,0) =          0._R_P              ; c(2,2,0) = 2292397033._R_P/ 1024803._R_P
    !             (i-3)*(i-2)              ;                (i-4)*(i-2)              ;                (i-5)*(i-2)
    c(3,2,0) =-378281867._R_P/   99229._R_P; c(4,2,0) = 1328498639._R_P/  803154._R_P; c(5,2,0) = -115324682._R_P/  395671._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,3,0) =         0._R_P              ; c(1,3,0) =          0._R_P              ; c(2,3,0) =          0._R_P
    !             (i-3)*(i-3)              ;                (i-4)*(i-3)              ;                (i-5)*(i-3)
    c(3,3,0) =1406067637._R_P/  859229._R_P; c(4,3,0) =-2146148426._R_P/ 1503065._R_P; c(5,3,0) =  586668707._R_P/ 2322432._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,4,0) =         0._R_P              ; c(1,4,0) =          0._R_P              ; c(2,4,0) =         0._R_P
    !                  /                   ;                (i-4)*(i-4)              ;                (i-5)*(i-4)
    c(3,4,0) =         0._R_P              ; c(4,4,0) =  453375035._R_P/ 1449454._R_P; c(5,4,0) = -504893127._R_P/ 4547012._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,5,0) =         0._R_P              ; c(1,5,0) =          0._R_P              ; c(2,5,0) =          0._R_P
    !                  /                   ;                     /                   ;                (i-5)*(i-5)
    c(3,5,0) =         0._R_P              ; c(4,5,0) =          0._R_P              ; c(5,5,0) =  105552913._R_P/10682745._R_P
    ! stencil 1
    !             (i+1)*(i+1)              ;                    i*(i+1)              ;                (i-1)*(i+1)
    c(0,0,1) = 105552913._R_P/10682745._R_P; c(1,0,1) = -338120165._R_P/ 4351341._R_P; c(2,0,1) =  356490569._R_P/ 2842289._R_P
    !             (i-2)*(i+1)              ;                (i-3)*(i+1)              ;                (i-4)*(i+1)
    c(3,0,1) =-146902225._R_P/ 1415767._R_P; c(4,0,1) =  195395281._R_P/ 4459947._R_P; c(5,0,1) =  -24044484._R_P/ 3193217._R_P

    !                  /                   ;                    i*i                  ;                (i-1)*i
    c(0,1,1) =         0._R_P              ; c(1,1,1) =  169505788._R_P/ 1035915._R_P; c(2,1,1) =-2984991531._R_P/ 5434265._R_P
    !             (i-2)*i                  ;                (i-3)*i                  ;                (i-4)*i
    c(3,1,1) = 771393469._R_P/ 1663855._R_P; c(4,1,1) = -270758311._R_P/ 1365867._R_P; c(5,1,1) =   26449004._R_P/  769961._R_P

    !                  /                   ;                     /                   ;                (i-1)*(i-1)
    c(0,2,1) =         0._R_P              ; c(1,2,1) =          0._R_P              ; c(2,2,1) =  471933572._R_P/  993629._R_P
    !             (i-2)*(i-1)              ;                (i-3)*(i-1)              ;                (i-4)*(i-1)
    c(3,2,1) =-479783044._R_P/  585775._R_P; c(4,2,1) =  840802608._R_P/ 2367661._R_P; c(5,2,1) = -347085621._R_P/ 5587817._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,3,1) =         0._R_P              ; c(1,3,1) =          0._R_P              ; c(2,3,1) =          0._R_P
    !             (i-2)*(i-2)              ;                (i-3)*(i-2)              ;                (i-4)*(i-2)
    c(3,3,1) =1031953342._R_P/ 2867575._R_P; c(4,3,1) = -288641753._R_P/  912148._R_P; c(5,3,1) =  315600562._R_P/ 5645537._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,4,1) =         0._R_P              ; c(1,4,1) =          0._R_P              ; c(2,4,1) =          0._R_P
    !                  /                   ;                (i-3)*(i-3)              ;                (i-4)*(i-3)
    c(3,4,1) =         0._R_P              ; c(4,4,1) =  142936745._R_P/ 2029182._R_P; c(5,4,1) = -109600459._R_P/ 4359925._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,5,1) =         0._R_P              ; c(1,5,1) =          0._R_P              ; c(2,5,1) =          0._R_P
    !                  /                   ;                     /                   ;                (i-4)*(i-4)
    c(3,5,1) =         0._R_P              ; c(4,5,1) =          0._R_P              ; c(5,5,1) =   30913579._R_P/13651507._R_P
    ! stencil 2
    !             (i+2)*(i+2)              ;                (i+1)*(i+2)              ;                    i*(i+2)
    c(0,0,2) =  30913579._R_P/13651507._R_P; c(1,0,2) =  -87214523._R_P/ 4439774._R_P; c(2,0,2) =   99590409._R_P/ 2965471._R_P
    !             (i-1)*(i+2)              ;                (i-2)*(i+2)              ;                (i-3)*(i+2)
    c(3,0,2) = -95644735._R_P/ 3360137._R_P; c(4,0,2) =   79135747._R_P/ 6577234._R_P; c(5,0,2) =  -28962993._R_P/14228092._R_P

    !                  /                   ;                (i+1)*(i+1)              ;                    i*(i+1)
    c(0,1,2) =         0._R_P              ; c(1,1,2) =   24025059._R_P/  519766._R_P; c(2,1,2) = -370146220._R_P/ 2226351._R_P
    !             (i-1)*(i+1)              ;                (i-2)*(i+1)              ;                (i-3)*(i+1)
    c(3,1,2) =  87743770._R_P/  602579._R_P; c(4,1,2) =-1512485867._R_P/24006092._R_P; c(5,1,2) =  251883319._R_P/23224320._R_P

    !                  /                   ;                     /                   ;                    i*i
    c(0,2,2) =         0._R_P              ; c(1,2,2) =          0._R_P              ; c(2,2,2) =  200449727._R_P/  1269707._R_P
    !             (i-1)*i                  ;                (i-2)*i                  ;                (i-3)*i
    c(3,2,2) =-274966489._R_P/  950662._R_P; c(4,2,2) =  201365679._R_P/ 1563055._R_P; c(5,2,2) =  -61673356._R_P/ 2721737._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,3,2) =         0._R_P              ; c(1,3,2) =          0._R_P              ; c(2,3,2) =          0._R_P
    !             (i-1)*(i-1)              ;                (i-2)*(i-1)              ;                (i-3)*(i-1)
    c(3,3,2) = 586743463._R_P/ 4237706._R_P; c(4,3,2) = -723607356._R_P/ 5654437._R_P; c(5,3,2) =  268747951._R_P/11612160._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,4,2) =         0._R_P              ; c(1,4,2) =          0._R_P              ; c(2,4,2) =          0._R_P
    !                  /                   ;                (i-2)*(i-2)              ;                (i-3)*(i-2)
    c(3,4,2) =         0._R_P              ; c(4,4,2) =  113243845._R_P/ 3672222._R_P; c(5,4,2) =  -74146214._R_P/ 6413969._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,5,2) =         0._R_P              ; c(1,5,2) =          0._R_P              ; c(2,5,2) =          0._R_P
    !                  /                   ;                     /                   ;                (i-3)*(i-3)
    c(3,5,2) =         0._R_P              ; c(4,5,2) =          0._R_P              ; c(5,5,2) =   15418339._R_P/13608685._R_P
    ! stencil 3
    !             (i+3)*(i+3)              ;                (i+2)*(i+3)              ;                (i+1)*(i+3)
    c(0,0,3) =  15418339._R_P/13608685._R_P; c(1,0,3) =  -74146214._R_P/ 6413969._R_P; c(2,0,3) =  268747951._R_P/11612160._R_P
    !                 i*(i+3)              ;                (i-1)*(i+3)              ;                (i-2)*(i+3)
    c(3,0,3) = -61673356._R_P/ 2721737._R_P; c(4,0,3) =  251883319._R_P/23224320._R_P; c(5,0,3) =  -28962993._R_P/14228092._R_P

    !                  /                   ;                (i+2)*(i+2)              ;                (i+1)*(i+2)
    c(0,1,3) =         0._R_P              ; c(1,1,3) =  113243845._R_P/ 3672222._R_P; c(2,1,3) = -723607356._R_P/ 5654437._R_P
    !                 i*(i+2)              ;                (i-1)*(i+2)              ;                (i-2)*(i+2)
    c(3,1,3) = 201365679._R_P/ 1563055._R_P; c(4,1,3) =-1512485867._R_P/24006092._R_P; c(5,1,3) =   79135747._R_P/ 6577234._R_P

    !                  /                   ;                     /                   ;                (i+1)*(i+1)
    c(0,2,3) =         0._R_P              ; c(1,2,3) =          0._R_P              ; c(2,2,3) =  586743463._R_P/ 4237706._R_P
    !                 i*(i+1)              ;                (i-1)*(i+1)              ;                (i-2)*(i+1)
    c(3,2,3) =-274966489._R_P/  950662._R_P; c(4,2,3) =   87743770._R_P/  602579._R_P; c(5,2,3) =  -95644735._R_P/ 3360137._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,3,3) =         0._R_P              ; c(1,3,3) =          0._R_P              ; c(2,3,3) =          0._R_P
    !                 i*i                  ;                (i-1)*i                  ;                (i-2)*i
    c(3,3,3) = 200449727._R_P/ 1269707._R_P; c(4,3,3) = -370146220._R_P/ 2226351._R_P; c(5,3,3) =   99590409._R_P/ 2965471._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,4,3) =         0._R_P              ; c(1,4,3) =          0._R_P              ; c(2,4,3) =          0._R_P
    !                  /                   ;                (i-1)*(i-1)              ;                (i-2)*(i-1)
    c(3,4,3) =         0._R_P              ; c(4,4,3) =   24025059._R_P/  519766._R_P; c(5,4,3) =  -87214523._R_P/ 4439774._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,5,3) =         0._R_P              ; c(1,5,3) =          0._R_P              ; c(2,5,3) =          0._R_P
    !                  /                   ;                     /                   ;                (i-2)*(i-2)
    c(3,5,3) =         0._R_P              ; c(4,5,3) =          0._R_P              ; c(5,5,3) =   30913579._R_P/13651507._R_P
    ! stencil 4
    !             (i+4)*(i+4)              ;                (i+3)*(i+4)              ;                (i+2)*(i+4)
    c(0,0,4) =  30913579._R_P/13651507._R_P; c(1,0,4) = -109600459._R_P/ 4359925._R_P; c(2,0,4) =  315600562._R_P/ 5645537._R_P
    !             (i+1)*(i+4)              ;                    i*(i+4)              ;                (i-1)*(i+4)
    c(3,0,4) =-347085621._R_P/ 5587817._R_P; c(4,0,4) =   26449004._R_P/  769961._R_P; c(5,0,4) =  -24044484._R_P/ 3193217._R_P

    !                  /                   ;                (i+3)*(i+3)              ;                (i+2)*(i+3)
    c(0,1,4) =         0._R_P              ; c(1,1,4) =  142936745._R_P/ 2029182._R_P; c(2,1,4) = -288641753._R_P/  912148._R_P
    !             (i+1)*(i+3)              ;                    i*(i+3)              ;                (i-1)*(i+3)
    c(3,1,4) = 840802608._R_P/ 2367661._R_P; c(4,1,4) = -270758311._R_P/ 1365867._R_P; c(5,1,4) =  195395281._R_P/ 4459947._R_P

    !                  /                   ;                     /                   ;                (i+2)*(i+2)
    c(0,2,4) =         0._R_P              ; c(1,2,4) =          0._R_P              ; c(2,2,4) = 1031953342._R_P/ 2867575._R_P
    !             (i+1)*(i+2)              ;                    i*(i+2)              ;                (i-1)*(i+2)
    c(3,2,4) =-479783044._R_P/  585775._R_P; c(4,2,4) =  771393469._R_P/ 1663855._R_P; c(5,2,4) = -146902225._R_P/ 1415767._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,3,4) =         0._R_P              ; c(1,3,4) =          0._R_P              ; c(2,3,4) =          0._R_P
    !             (i+1)*(i+1)              ;                    i*(i+1)              ;                (i-1)*(i+1)
    c(3,3,4) = 471933572._R_P/  993629._R_P; c(4,3,4) =-2984991531._R_P/ 5434265._R_P; c(5,3,4) =  356490569._R_P/ 2842289._R_P

    !                  /                   ;                     /                   ;                      /
    c(0,4,4) =         0._R_P              ; c(1,4,4) =          0._R_P              ; c(2,4,4) =          0._R_P
    !                  /                   ;                    i*i                  ;                (i-1)*i
    c(3,4,4) =         0._R_P              ; c(4,4,4) =  169505788._R_P/ 1035915._R_P; c(5,4,4) = -338120165._R_P/ 4351341._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,5,4) =         0._R_P              ; c(1,5,4) =          0._R_P              ; c(2,5,4) =          0._R_P
    !                  /                   ;                     /                   ;                (i-1)*(i-1)
    c(3,5,4) =         0._R_P              ; c(4,5,4) =          0._R_P              ; c(5,5,4) =  105552913._R_P/10682745._R_P
    ! stencil 5
    !             (i+5)*(i+5)              ;                (i+4)*(i+5)              ;                (i+3)*(i+5)
    c(0,0,5) = 105552913._R_P/10682745._R_P; c(1,0,5) = -504893127._R_P/ 4547012._R_P; c(2,0,5) =  586668707._R_P/ 2322432._R_P
    !             (i+2)*(i+5)              ;                (i+1)*(i+5)              ;                    i*(i+5)
    c(3,0,5) =-115324682._R_P/  395671._R_P; c(4,0,5) =  112453613._R_P/  657635._R_P; c(5,0,5) = -131759526._R_P/ 3224383._R_P

    !                  /                   ;                (i+4)*(i+3)              ;                (i+3)*(i+3)
    c(0,1,5) =         0._R_P              ; c(1,1,5) =  453375035._R_P/ 1449454._R_P; c(2,1,5) =-2146148426._R_P/ 1503065._R_P
    !             (i+2)*(i+3)              ;                (i+1)*(i+3)              ;                    i*(i+3)
    c(3,1,5) =1328498639._R_P/  803154._R_P; c(4,1,5) = -674462631._R_P/  691651._R_P; c(5,1,5) =  295095211._R_P/ 1259192._R_P

    !                  /                   ;                     /                   ;                (i+3)*(i+2)
    c(0,2,5) =         0._R_P              ; c(1,2,5) =          0._R_P              ; c(2,2,5) = 1406067637._R_P/  859229._R_P
    !             (i+2)*(i+2)              ;                (i+1)*(i+2)              ;                    i*(i+2)
    c(3,2,5) =-378281867._R_P/   99229._R_P; c(4,2,5) = 1150428332._R_P/  508385._R_P; c(5,2,5) = -427867945._R_P/  780329._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,3,5) =         0._R_P              ; c(1,3,5) =          0._R_P              ; c(2,3,5) =          0._R_P
    !             (i+2)*(i+1)              ;                (i+1)*(i+1)              ;                    i*(i+1)
    c(3,3,5) =2292397033._R_P/ 1024803._R_P; c(4,3,5) = -497421494._R_P/  185427._R_P; c(5,3,5) =  497902668._R_P/  756325._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,4,5) =         0._R_P              ; c(1,4,5) =          0._R_P              ; c(2,4,5) =          0._R_P
    !                  /                   ;                (i+1)*i                  ;                    i*i
    c(3,4,5) =         0._R_P              ; c(4,4,5) =  498196769._R_P/  609968._R_P; c(5,4,5) = -157371280._R_P/  384113._R_P

    !                  /                   ;                     /                   ;                     /
    c(0,5,5) =         0._R_P              ; c(1,5,5) =          0._R_P              ; c(2,5,5) =          0._R_P
    !                  /                   ;                     /                   ;                    i*(i-1)
    c(3,5,5) =         0._R_P              ; c(4,5,5) =          0._R_P              ; c(5,5,5) =  373189088._R_P/ 7027375._R_P
  case(7) ! 13th order
    ! stencil 0
    !                   i*i                   ;                   (i-1)*i
    c(0,0,0) =     307570060._R_P/2438487._R_P; c(1,0,0) = -842151863._R_P/702281._R_P
    !                  (i-2)*i                ;                   (i-3)*i
    c(2,0,0) =  1025357155._R_P/415733._R_P; c(3,0,0) = -882134137._R_P/316505._R_P
    !                  (i-4)*i                ;                   (i-5)*i
    c(4,0,0) =    2375865880._R_P/1312047._R_P; c(5,0,0) =   -418267211._R_P/655432._R_P
    !                  (i-6)*i
    c(6,0,0) =   65647731._R_P/691205._R_P

    !                    /                    ;                   (i-1)*(i-1)
    c(0,1,0) =                          0._R_P; c(1,1,0) =    1267010831._R_P/433225._R_P
    !                  (i-2)*(i-1)            ;                   (i-3)*(i-1)
    c(2,1,0) =    -2727583905._R_P/223057._R_P; c(3,1,0) =   2854637563._R_P/204507._R_P
    !                  (i-4)*(i-1)            ;                   (i-5)*(i-1)
    c(4,1,0) =  -550697211._R_P/60310._R_P; c(5,1,0) =    803154527._R_P/248375._R_P
    !                  (i-6)*(i-1)
    c(6,1,0) =  -299800985._R_P/620702._R_P

    !                    /                    ;                     /
    c(0,2,0) =                          0._R_P; c(1,2,0) =                          0._R_P
    !                  (i-2)*(i-2)            ;                   (i-3)*(i-2)
    c(2,2,0) =     2398154453._R_P/185516._R_P; c(3,2,0) =   -485497721._R_P/16325._R_P
    !                  (i-4)*(i-2)            ;                   (i-5)*(i-2)
    c(4,2,0) =     3315206316._R_P/169489._R_P; c(5,2,0) =  -1068783425._R_P/153683._R_P
    !                  (i-6)*(i-2)
    c(6,2,0) =    412399715._R_P/395812._R_P

    !                    /                    ;                     /
    c(0,3,0) =                          0._R_P; c(1,3,0) =                          0._R_P
    !                    /                    ;                   (i-3)*(i-3)
    c(2,3,0) =                          0._R_P; c(3,3,0) =   2558389867._R_P/148729._R_P
    !                  (i-4)*(i-3)            ;                   (i-5)*(i-3)
    c(4,3,0) =   -1833856939._R_P/80705._R_P; c(5,3,0) =   2369766527._R_P/292389._R_P
    !                  (i-6)*(i-3)
    c(6,3,0) = -219701291._R_P/180490._R_P

    !                    /                    ;                     /
    c(0,4,0) =                          0._R_P; c(1,4,0) =                          0._R_P
    !                    /                    ;                     /
    c(2,4,0) =                          0._R_P; c(3,4,0) =                          0._R_P
    !                  (i-4)*(i-4)            ;                   (i-5)*(i-4)
    c(4,4,0) =       384888217._R_P/51123._R_P; c(5,4,0) =    -3101495154._R_P/576017._R_P
    !                  (i-6)*(i-4)
    c(6,4,0) =  562957181._R_P/694753._R_P

    !                    /                    ;                     /
    c(0,5,0) =                          0._R_P; c(1,5,0) =                          0._R_P
    !                    /                    ;                     /
    c(2,5,0) =                          0._R_P; c(3,5,0) =                          0._R_P
    !                    /                    ;                   (i-5)*(i-5)
    c(4,5,0) =                          0._R_P; c(5,5,0) =    368117849._R_P/381597._R_P
    !                  (i-6)*(i-5)
    c(6,5,0) = -484093752._R_P/1664533._R_P

    !                    /                    ;                     /
    c(0,6,0) =                          0._R_P; c(1,6,0) =                          0._R_P
    !                    /                    ;                     /
    c(2,6,0) =                          0._R_P; c(3,6,0) =                          0._R_P
    !                    /                    ;                     /
    c(4,6,0) =                          0._R_P; c(5,6,0) =                          0._R_P
    !                  (i-6)*(i-6)
    c(6,6,0) =      118739219._R_P/5409702._R_P
    ! stencil 1
    !                  (i+1)*(i+1)            ;                    i*(i+1)
    c(0,0,1) =      118739219._R_P/5409702._R_P; c(1,0,1) =  -258813979._R_P/1219012._R_P
    !                  (i-1)*(i+1)            ;                   (i-2)*(i+1)
    c(2,0,1) =    451414666._R_P/1028589._R_P; c(3,0,1) =  -219042731._R_P/442919._R_P
    !                  (i-3)*(i+1)            ;                   (i-4)*(i+1)
    c(4,0,1) =    200564827._R_P/628331._R_P; c(5,0,1) =    -1157045253._R_P/10370330._R_P
    !                  (i-5)*(i+1)
    c(6,0,1) =    43003346._R_P/2612319._R_P

    !                    /                    ;                       i*(i-1)
    c(0,1,1) =                          0._R_P; c(1,1,1) =      151821033._R_P/282817._R_P
    !                  (i-1)*(i-1)            ;                   (i-2)*(i-1)
    c(2,1,1) =  -2876116249._R_P/1263255._R_P; c(3,1,1) =   6598378479._R_P/2533904._R_P
    !                  (i-3)*(i-1)            ;                   (i-4)*(i-1)
    c(4,1,1) =     -448069659._R_P/263978._R_P; c(5,1,1) =    1029357835._R_P/1723277._R_P
    !                  (i-5)*(i-1)
    c(6,1,1) =    -265505701._R_P/2998139._R_P

    !                    /                    ;                    /
    c(0,2,1) =                          0._R_P; c(1,2,1) =                          0._R_P
    !                  (i-1)*(i-2)            ;                   (i-3)*(i-2)
    c(2,2,1) =      3295939303._R_P/1339169._R_P; c(3,2,1) =     -952714155._R_P/166894._R_P
    !                  (i-4)*(i-2)            ;                   (i-5)*(i-2)
    c(4,2,1) =    656116894._R_P/174649._R_P; c(5,2,1) =   -577579349._R_P/433921._R_P
    !                  (i-6)*(i-2)
    c(6,2,1) =     265135851._R_P/1336964._R_P

    !                    /                    ;                     /
    c(0,3,1) =                          0._R_P; c(1,3,1) =                          0._R_P
    !                    /                    ;                   (i-2)*(i-3)
    c(2,3,1) =                          0._R_P; c(3,3,1) =    353679247._R_P/105637._R_P
    !                  (i-3)*(i-3)            ;                   (i-4)*(i-3)
    c(4,3,1) =    -1397796418._R_P/314477._R_P; c(5,3,1) =      498890606._R_P/314761._R_P
    !                  (i-5)*(i-3)
    c(6,3,1) =  -246865952._R_P/1040433._R_P

    !                    /                    ;                     /
    c(0,4,1) =                          0._R_P; c(1,4,1) =                          0._R_P
    !                    /                    ;                     /
    c(2,4,1) =                          0._R_P; c(3,4,1) =                          0._R_P
    !                  (i-3)*(i-4)            ;                   (i-4)*(i-4)
    c(4,4,1) =        1142129285._R_P/768659._R_P; c(5,4,1) =   -185662673._R_P/174204._R_P
    !                  (i-5)*(i-4)
    c(6,4,1) =  1743860591._R_P/10881504._R_P

    !                    /                    ;                     /
    c(0,5,1) =                          0._R_P; c(1,5,1) =                          0._R_P
    !                    /                    ;                     /
    c(2,5,1) =                          0._R_P; c(3,5,1) =                          0._R_P
    !                    /                    ;                   (i-5)*(i-5)
    c(4,5,1) =                          0._R_P; c(5,5,1) =    393580372._R_P/2049353._R_P
    !                  (i-6)*(i-5)
    c(6,5,1) =    -483420287._R_P/8336284._R_P

    !                    /                    ;                     /
    c(0,6,1) =                          0._R_P; c(1,6,1) =                          0._R_P
    !                    /                    ;                     /
    c(2,6,1) =                          0._R_P; c(3,6,1) =                          0._R_P
    !                    /                    ;                     /
    c(4,6,1) =                          0._R_P; c(5,6,1) =                          0._R_P
    !                  (i-6)*(i-5)
    c(6,6,1) =     76695443._R_P/17458022._R_P
    ! stencil 2
    !                  (i+2)*i                ;                   (i+1)*i
    c(0,0,2) =     76695443._R_P/17458022._R_P; c(1,0,2) =   -303410983._R_P/6736159._R_P
    !                      i*i                ;                   (i-1)*i
    c(2,0,2) =   305770890._R_P/3186613._R_P; c(3,0,2) = -337645273._R_P/3091776._R_P
    !                  (i-2)*i                ;                   (i-3)*i
    c(4,0,2) =     164871587._R_P/2347023._R_P; c(5,0,2) =    -205305705._R_P/8465339._R_P
    !                  (i-4)*i
    c(6,0,2) =       77150072._R_P/21955151._R_P

    !                    /                    ;                   (i+1)*(i-1)
    c(0,1,2) =                          0._R_P; c(1,1,2) =     266980515._R_P/2188712._R_P
    !                      i*(i-1)            ;                   (i-1)*(i-1)
    c(2,1,2) =   -470895955._R_P/874781._R_P; c(3,1,2) =    337717185._R_P/538487._R_P
    !                  (i-2)*(i-1)            ;                   (i-3)*(i-1)
    c(4,1,2) =   -1002866209._R_P/2445347._R_P; c(5,1,2) =     154914521._R_P/1081252._R_P
    !                  (i-4)*(i-1)
    c(6,1,2) =      -98152843._R_P/4687720._R_P

    !                    /                    ;                    /
    c(0,2,2) =                          0._R_P; c(1,2,2) =                          0._R_P
        !                  i*(i-1)            ;                   (i-1)*(i-2)
    c(2,2,2) =        576629617._R_P/938378._R_P; c(3,2,2) =    -631316405._R_P/429286._R_P
    !                  (i-2)*(i-2)            ;                   (i-3)*(i-2)
    c(4,2,2) =    750365573._R_P/765885._R_P; c(5,2,2) =    -251896262._R_P/725959._R_P
    !                  (i-4)*(i-2)
    c(6,2,2) =     143992467._R_P/2811164._R_P

    !                    /                    ;                     /
    c(0,3,2) =                          0._R_P; c(1,3,2) =                          0._R_P
    !                    /                    ;                   (i-1)*(i-3)
    c(2,3,2) =                          0._R_P; c(3,3,2) =    449371687._R_P/498274._R_P
    !                  (i-2)*(i-3)            ;                   (i-3)*(i-3)
    c(4,3,2) =     -660635886._R_P/538753._R_P; c(5,3,2) =    13260333719._R_P/30064515._R_P
    !                  (i-4)*(i-3)
    c(6,3,2) =   -177311125._R_P/2691566._R_P

    !                    /                    ;                     /
    c(0,4,2) =                          0._R_P; c(1,4,2) =                          0._R_P
    !                    /                    ;                     /
    c(2,4,2) =                          0._R_P; c(3,4,2) =                          0._R_P
    !                  (i-2)*(i-4)            ;                   (i-3)*(i-4)
    c(4,4,2) =      787491691._R_P/1852394._R_P; c(5,4,2) =   -393831298._R_P/1266551._R_P
    !                  (i-4)*(i-4)
    c(6,4,2) =     85769455._R_P/1822342._R_P

    !                    /                    ;                     /
    c(0,5,2) =                          0._R_P; c(1,5,2) =                          0._R_P
    !                    /                    ;                     /
    c(2,5,2) =                          0._R_P; c(3,5,2) =                          0._R_P
    !                    /                    ;                   (i-3)*(i-5)
    c(4,5,2) =                          0._R_P; c(5,5,2) =     309673793._R_P/5357421._R_P
    !                  (i-4)*(i-5)
    c(6,5,2) =   -86513123._R_P/4872070._R_P

    !                    /                    ;                     /
    c(0,6,2) =                          0._R_P; c(1,6,2) =                          0._R_P
    !                    /                    ;                     /
    c(2,6,2) =                          0._R_P; c(3,6,2) =                          0._R_P
    !                    /                    ;                     /
    c(4,6,2) =                          0._R_P; c(5,6,2) =                          0._R_P
    !                  (i-4)*(i-5)
    c(6,6,2) =       20823809._R_P/15031645._R_P
    ! stencil 3
    !                  (i+3)*i                ;                   (i+2)*i
    c(0,0,3) =       20823809._R_P/15031645._R_P; c(1,0,3) =  -85952276._R_P/5412389._R_P
    !                  (i+1)*i                ;                       i*i
    c(2,0,3) =    97747719._R_P/2624408._R_P; c(3,0,3) =  -77947404._R_P/1703711._R_P
    !                  (i-1)*i                ;                   (i-2)*i
    c(4,0,3) =     78098218._R_P/2511469._R_P; c(5,0,3) =  -31210580._R_P/2807109._R_P
    !                  (i-3)*i
    c(6,0,3) =     29187600._R_P/17822477._R_P

    !                    /                    ;                   (i+1)*(i-1)
    c(0,1,3) =                          0._R_P; c(1,1,3) =     151133283._R_P/3169976._R_P
    !                      i*(i-1)            ;                   (i-1)*(i-1)
    c(2,1,3) =     -735436149._R_P/3170423._R_P; c(3,1,3) =    212799192._R_P/725717._R_P
    !                  (i-2)*(i-1)            ;                   (i-3)*(i-1)
    c(4,1,3) =    -7192946466._R_P/35277791._R_P; c(5,1,3) =      143433946._R_P/1930931._R_P
    !                  (i-4)*(i-1)
    c(6,1,3) =   -31210580._R_P/2807109._R_P

    !                    /                    ;                    /
    c(0,2,3) =                          0._R_P; c(1,2,3) =                          0._R_P
        !                  i*(i-1)            ;                   (i-1)*(i-2)
    c(2,2,3) =        330842346._R_P/1128355._R_P; c(3,2,3) =     -478256390._R_P/624157._R_P
    !                  (i-2)*(i-2)            ;                   (i-3)*(i-2)
    c(4,2,3) =      1046376941._R_P/1911720._R_P; c(5,2,3) =    -7192946466._R_P/35277791._R_P
    !                  (i-4)*(i-2)
    c(6,2,3) =     78098218._R_P/2511469._R_P

    !                    /                    ;                     /
    c(0,3,3) =                          0._R_P; c(1,3,3) =                          0._R_P
    !                    /                    ;                   (i-1)*(i-3)
    c(2,3,3) =                          0._R_P; c(3,3,3) =    1393876129._R_P/2686891._R_P
    !                  (i-2)*(i-3)            ;                   (i-3)*(i-3)
    c(4,3,3) =     -478256390._R_P/624157._R_P; c(5,3,3) =    212799192._R_P/725717._R_P
    !                  (i-4)*(i-3)
    c(6,3,3) =   -77947404._R_P/1703711._R_P

    !                    /                    ;                     /
    c(0,4,3) =                          0._R_P; c(1,4,3) =                          0._R_P
    !                    /                    ;                     /
    c(2,4,3) =                          0._R_P; c(3,4,3) =                          0._R_P
    !                  (i-2)*(i-4)            ;                   (i-3)*(i-4)
    c(4,4,3) =        330842346._R_P/1128355._R_P; c(5,4,3) =     -735436149._R_P/3170423._R_P
    !                  (i-4)*(i-4)
    c(6,4,3) =    97747719._R_P/2624408._R_P

    !                    /                    ;                     /
    c(0,5,3) =                          0._R_P; c(1,5,3) =                          0._R_P
    !                    /                    ;                     /
    c(2,5,3) =                          0._R_P; c(3,5,3) =                          0._R_P
    !                    /                    ;                   (i-3)*(i-5)
    c(4,5,3) =                          0._R_P; c(5,5,3) =     151133283._R_P/3169976._R_P
    !                  (i-4)*(i-5)
    c(6,5,3) =   -85952276._R_P/5412389._R_P

    !                    /                    ;                     /
    c(0,6,3) =                          0._R_P; c(1,6,3) =                          0._R_P
    !                    /                    ;                     /
    c(2,6,3) =                          0._R_P; c(3,6,3) =                          0._R_P
    !                    /                    ;                     /
    c(4,6,3) =                          0._R_P; c(5,6,3) =                          0._R_P
    !                  (i-4)*(i-5)
    c(6,6,3) =       20823809._R_P/15031645._R_P
    ! stencil 4
    !                  (i+3)*i                ;                   (i+2)*i
    c(0,0,4) =       20823809._R_P/15031645._R_P; c(1,0,4) =  -86513123._R_P/4872070._R_P
    !                  (i+1)*i                ;                       i*i
    c(2,0,4) =     85769455._R_P/1822342._R_P; c(3,0,4) =  -177311125._R_P/2691566._R_P
    !                  (i-1)*i                ;                   (i-2)*i
    c(4,0,4) =     143992467._R_P/2811164._R_P; c(5,0,4) =     -98152843._R_P/4687720._R_P
    !                  (i-3)*i
    c(6,0,4) =       77150072._R_P/21955151._R_P

    !                    /                    ;                   (i+1)*(i-1)
    c(0,1,4) =                          0._R_P; c(1,1,4) =     309673793._R_P/5357421._R_P
    !                      i*(i-1)            ;                   (i-1)*(i-1)
    c(2,1,4) =   -393831298._R_P/1266551._R_P; c(3,1,4) =    13260333719._R_P/30064515._R_P
    !                  (i-2)*(i-1)            ;                   (i-3)*(i-1)
    c(4,1,4) =    -251896262._R_P/725959._R_P; c(5,1,4) =     154914521._R_P/1081252._R_P
    !                  (i-4)*(i-1)
    c(6,1,4) =     -205305705._R_P/8465339._R_P

    !                    /                    ;                    /
    c(0,2,4) =                          0._R_P; c(1,2,4) =                          0._R_P
        !                  i*(i-1)            ;                   (i-1)*(i-2)
    c(2,2,4) =      787491691._R_P/1852394._R_P; c(3,2,4) =     -660635886._R_P/538753._R_P
    !                  (i-2)*(i-2)            ;                   (i-3)*(i-2)
    c(4,2,4) =    750365573._R_P/765885._R_P; c(5,2,4) =   -1002866209._R_P/2445347._R_P
    !                  (i-4)*(i-2)
    c(6,2,4) =     164871587._R_P/2347023._R_P

    !                    /                    ;                     /
    c(0,3,4) =                          0._R_P; c(1,3,4) =                          0._R_P
    !                    /                    ;                   (i-1)*(i-3)
    c(2,3,4) =                          0._R_P; c(3,3,4) =    449371687._R_P/498274._R_P
    !                  (i-2)*(i-3)            ;                   (i-3)*(i-3)
    c(4,3,4) =    -631316405._R_P/429286._R_P; c(5,3,4) =    337717185._R_P/538487._R_P
    !                  (i-4)*(i-3)
    c(6,3,4) =  -337645273._R_P/3091776._R_P

    !                    /                    ;                     /
    c(0,4,4) =                          0._R_P; c(1,4,4) =                          0._R_P
    !                    /                    ;                     /
    c(2,4,4) =                          0._R_P; c(3,4,4) =                          0._R_P
    !                  (i-2)*(i-4)            ;                   (i-3)*(i-4)
    c(4,4,4) =        576629617._R_P/938378._R_P; c(5,4,4) =   -470895955._R_P/874781._R_P
    !                  (i-4)*(i-4)
    c(6,4,4) =   305770890._R_P/3186613._R_P

    !                    /                    ;                     /
    c(0,5,4) =                          0._R_P; c(1,5,4) =                          0._R_P
    !                    /                    ;                     /
    c(2,5,4) =                          0._R_P; c(3,5,4) =                          0._R_P
    !                    /                    ;                   (i-3)*(i-5)
    c(4,5,4) =                          0._R_P; c(5,5,4) =     266980515._R_P/2188712._R_P
    !                  (i-4)*(i-5)
    c(6,5,4) =    -303410983._R_P/6736159._R_P

    !                    /                    ;                     /
    c(0,6,4) =                          0._R_P; c(1,6,4) =                          0._R_P
    !                    /                    ;                     /
    c(2,6,4) =                          0._R_P; c(3,6,4) =                          0._R_P
    !                    /                    ;                     /
    c(4,6,4) =                          0._R_P; c(5,6,4) =                          0._R_P
    !                  (i-4)*(i-5)
    c(6,6,4) =     76695443._R_P/17458022._R_P
    ! stencil 5
    !                  (i+3)*i                ;                   (i+2)*i
    c(0,0,5) =     76695443._R_P/17458022._R_P; c(1,0,5) =    -483420287._R_P/8336284._R_P
    !                  (i+1)*i                ;                       i*i
    c(2,0,5) =   1743860591._R_P/10881504._R_P; c(3,0,5) =  -246865952._R_P/1040433._R_P
    !                  (i-1)*i                ;                   (i-2)*i
    c(4,0,5) =     265135851._R_P/1336964._R_P; c(5,0,5) =    -265505701._R_P/2998139._R_P
    !                  (i-3)*i
    c(6,0,5) =    43003346._R_P/2612319._R_P

    !                    /                    ;                   (i+1)*(i-1)
    c(0,1,5) =                          0._R_P; c(1,1,5) =    393580372._R_P/2049353._R_P
    !                      i*(i-1)            ;                   (i-1)*(i-1)
    c(2,1,5) =   -185662673._R_P/174204._R_P; c(3,1,5) =      498890606._R_P/314761._R_P
    !                  (i-2)*(i-1)            ;                   (i-3)*(i-1)
    c(4,1,5) =   -577579349._R_P/433921._R_P; c(5,1,5) =    1029357835._R_P/1723277._R_P
    !                  (i-4)*(i-1)
    c(6,1,5) =    -1157045253._R_P/10370330._R_P

    !                    /                    ;                    /
    c(0,2,5) =                          0._R_P; c(1,2,5) =                          0._R_P
        !                  i*(i-1)            ;                   (i-1)*(i-2)
    c(2,2,5) =        1142129285._R_P/768659._R_P; c(3,2,5) =    -1397796418._R_P/314477._R_P
    !                  (i-2)*(i-2)            ;                   (i-3)*(i-2)
    c(4,2,5) =    656116894._R_P/174649._R_P; c(5,2,5) =     -448069659._R_P/263978._R_P
    !                  (i-4)*(i-2)
    c(6,2,5) =    200564827._R_P/628331._R_P

    !                    /                    ;                     /
    c(0,3,5) =                          0._R_P; c(1,3,5) =                          0._R_P
    !                    /                    ;                   (i-1)*(i-3)
    c(2,3,5) =                          0._R_P; c(3,3,5) =    353679247._R_P/105637._R_P
    !                  (i-2)*(i-3)            ;                   (i-3)*(i-3)
    c(4,3,5) =     -952714155._R_P/166894._R_P; c(5,3,5) =   6598378479._R_P/2533904._R_P
    !                  (i-4)*(i-3)
    c(6,3,5) =  -219042731._R_P/442919._R_P

    !                    /                    ;                     /
    c(0,4,5) =                          0._R_P; c(1,4,5) =                          0._R_P
    !                    /                    ;                     /
    c(2,4,5) =                          0._R_P; c(3,4,5) =                          0._R_P
    !                  (i-2)*(i-4)            ;                   (i-3)*(i-4)
    c(4,4,5) =      3295939303._R_P/1339169._R_P; c(5,4,5) =  -2876116249._R_P/1263255._R_P
    !                  (i-4)*(i-4)
    c(6,4,5) =    451414666._R_P/1028589._R_P

    !                    /                    ;                     /
    c(0,5,5) =                          0._R_P; c(1,5,5) =                          0._R_P
    !                    /                    ;                     /
    c(2,5,5) =                          0._R_P; c(3,5,5) =                          0._R_P
    !                    /                    ;                   (i-3)*(i-5)
    c(4,5,5) =                          0._R_P; c(5,5,5) =      151821033._R_P/282817._R_P
    !                  (i-4)*(i-5)
    c(6,5,5) =  -258813979._R_P/1219012._R_P

    !                    /                    ;                     /
    c(0,6,5) =                          0._R_P; c(1,6,5) =                          0._R_P
    !                    /                    ;                     /
    c(2,6,5) =                          0._R_P; c(3,6,5) =                          0._R_P
    !                    /                    ;                     /
    c(4,6,5) =                          0._R_P; c(5,6,5) =                          0._R_P
    !                  (i-4)*(i-5)
    c(6,6,5) =      118739219._R_P/5409702._R_P
    ! stencil 6
    !                  (i+3)*i                ;                   (i+2)*i
    c(0,0,6) =      118739219._R_P/5409702._R_P; c(1,0,6) =  -484093752._R_P/1664533._R_P
    !                  (i+1)*i                ;                       i*i
    c(2,0,6) =  562957181._R_P/694753._R_P; c(3,0,6) = -219701291._R_P/180490._R_P
    !                  (i-1)*i                ;                   (i-2)*i
    c(4,0,6) =    412399715._R_P/395812._R_P; c(5,0,6) =  -299800985._R_P/620702._R_P
    !                  (i-3)*i
    c(6,0,6) =   65647731._R_P/691205._R_P

    !                    /                    ;                   (i+1)*(i-1)
    c(0,1,6) =                          0._R_P; c(1,1,6) =    368117849._R_P/381597._R_P
    !                      i*(i-1)            ;                   (i-1)*(i-1)
    c(2,1,6) =    -3101495154._R_P/576017._R_P; c(3,1,6) =   2369766527._R_P/292389._R_P
    !                  (i-2)*(i-1)            ;                   (i-3)*(i-1)
    c(4,1,6) =  -1068783425._R_P/153683._R_P; c(5,1,6) =    803154527._R_P/248375._R_P
    !                  (i-4)*(i-1)
    c(6,1,6) =   -418267211._R_P/655432._R_P

    !                    /                    ;                    /
    c(0,2,6) =                          0._R_P; c(1,2,6) =                          0._R_P
        !                  i*(i-1)            ;                   (i-1)*(i-2)
    c(2,2,6) =       384888217._R_P/51123._R_P; c(3,2,6) =   -1833856939._R_P/80705._R_P
    !                  (i-2)*(i-2)            ;                   (i-3)*(i-2)
    c(4,2,6) =     3315206316._R_P/169489._R_P; c(5,2,6) =   -550697211._R_P/60310._R_P
    !                  (i-4)*(i-2)
    c(6,2,6) =    2375865880._R_P/1312047._R_P

    !                    /                    ;                     /
    c(0,3,6) =                          0._R_P; c(1,3,6) =                          0._R_P
    !                    /                    ;                   (i-1)*(i-3)
    c(2,3,6) =                          0._R_P; c(3,3,6) =   2558389867._R_P/148729._R_P
    !                  (i-2)*(i-3)            ;                   (i-3)*(i-3)
    c(4,3,6) =   -485497721._R_P/16325._R_P; c(5,3,6) =   2854637563._R_P/204507._R_P
    !                  (i-4)*(i-3)
    c(6,3,6) = -882134137._R_P/316505._R_P

    !                    /                    ;                     /
    c(0,4,6) =                          0._R_P; c(1,4,6) =                          0._R_P
    !                    /                    ;                     /
    c(2,4,6) =                          0._R_P; c(3,4,6) =                          0._R_P
    !                  (i-2)*(i-4)            ;                   (i-3)*(i-4)
    c(4,4,6) =     2398154453._R_P/185516._R_P; c(5,4,6) =    -2727583905._R_P/223057._R_P
    !                  (i-4)*(i-4)
    c(6,4,6) =  1025357155._R_P/415733._R_P

    !                    /                    ;                     /
    c(0,5,6) =                          0._R_P; c(1,5,6) =                          0._R_P
    !                    /                    ;                     /
    c(2,5,6) =                          0._R_P; c(3,5,6) =                          0._R_P
    !                    /                    ;                   (i-3)*(i-5)
    c(4,5,6) =                          0._R_P; c(5,5,6) =    1267010831._R_P/433225._R_P
    !                  (i-4)*(i-5)
    c(6,5,6) = -842151863._R_P/702281._R_P

    !                    /                    ;                     /
    c(0,6,6) =                          0._R_P; c(1,6,6) =                          0._R_P
    !                    /                    ;                     /
    c(2,6,6) =                          0._R_P; c(3,6,6) =                          0._R_P
    !                    /                    ;                     /
    c(4,6,6) =                          0._R_P; c(5,6,6) =                          0._R_P
    !                  (i-4)*(i-5)
    c(6,6,6) =     307570060._R_P/2438487._R_P
  case(8) ! 15th order
    ! stencil 0
    !                    /                              ;                      /
    c(0,0,0) =     561955582._R_P/  1878967._R_P; c(1,0,0) =    -1353623375._R_P/    398213._R_P
    !                    /                              ;                      /
    c(2,0,0) =    1512171950._R_P/   176773._R_P; c(3,0,0) =    -1384199219._R_P/    112909._R_P
    !                    /                              ;                      /
    c(4,0,0) =     1191775685._R_P/    110969._R_P; c(5,0,0) =    -6701525420._R_P/    1169941._R_P
    !                    /                              ;                      /
    c(6,0,0) =    1730988313._R_P/  1007913._R_P; c(7,0,0) =     -167817292._R_P/   753123._R_P

    !                    /                              ;                      /
    c(0,1,0) =                                    0._R_P; c(1,1,0) =   5230798390._R_P/  531001._R_P
    !                    /                              ;                      /
    c(2,1,0) =  -6783346413._R_P/   135128._R_P; c(3,1,0) =   2653665219._R_P/   36590._R_P
    !                    /                              ;                      /
    c(4,1,0) =     -2650855638._R_P/      41489._R_P; c(5,1,0) =  3436464517._R_P/  100426._R_P
    !                    /                              ;                      /
    c(6,1,0) =   -8115803171._R_P/   788565._R_P; c(7,1,0) =    1606637628._R_P/  1200199._R_P

    !                    /                              ;                      /
    c(0,2,0) =                                    0._R_P; c(1,2,0) =                                    0._R_P
    !                    /                              ;                      /
    c(2,2,0) =  3382169379._R_P/  52433._R_P; c(3,2,0) =    -4461330800._R_P/     23793._R_P
    !                    /                              ;                      /
    c(4,2,0) =   2354499851._R_P/   14191._R_P; c(5,2,0) =  -9679034365._R_P/   108568._R_P
    !                    /                              ;                      /
    c(6,2,0) =   4477231643._R_P/  166549._R_P; c(7,2,0) =    -2034860005._R_P/   580787._R_P

    !                    /                              ;                      /
    c(0,3,0) =                                    0._R_P; c(1,3,0) =                                    0._R_P
    !                    /                              ;                      /
    c(2,3,0) =                                    0._R_P; c(3,3,0) =     5383551615._R_P/     39332._R_P
    !                    /                              ;                      /
    c(4,3,0) =   -10453320754._R_P/    43009._R_P; c(5,3,0) =   7936751861._R_P/   60613._R_P
    !                    /                              ;                      /
    c(6,3,0) =    -3946887082._R_P/    99757._R_P; c(7,3,0) =    1168472761._R_P/   226223._R_P

    !                    /                              ;                      /
    c(0,4,0) =                                    0._R_P; c(1,4,0) =                                    0._R_P
    !                    /                              ;                      /
    c(2,4,0) =                                    0._R_P; c(3,4,0) =                                    0._R_P
    !                    /                              ;                      /
    c(4,4,0) =    15685259234._R_P/    144989._R_P; c(5,4,0) =     -2087501693._R_P/      17871._R_P
    !                    /                              ;                      /
    c(6,4,0) =    12211598186._R_P/   345407._R_P; c(7,4,0) =    -1774088813._R_P/    383858._R_P

    !                    /                              ;                      /
    c(0,5,0) =                                    0._R_P; c(1,5,0) =                                    0._R_P
    !                    /                              ;                      /
    c(2,5,0) =                                    0._R_P; c(3,5,0) =                                    0._R_P
    !                    /                              ;                      /
    c(4,5,0) =                                    0._R_P; c(5,5,0) =   5633451919._R_P/  178362._R_P
    !                    /                              ;                      /
    c(6,5,0) =   -1307164757._R_P/   68276._R_P; c(7,5,0) =    4932843539._R_P/   1968706._R_P

    !                    /                              ;                      /
    c(0,6,0) =                                    0._R_P; c(1,6,0) =                                    0._R_P
    !                    /                              ;                      /
    c(2,6,0) =                                    0._R_P; c(3,6,0) =                                    0._R_P
    !                    /                              ;                      /
    c(4,6,0) =                                    0._R_P; c(5,6,0) =                                    0._R_P
    !                    /                              ;                      /
    c(6,6,0) =   1285415788._R_P/  442547._R_P; c(7,6,0) =    -508083143._R_P/   667663._R_P

    !                    /                              ;                      /
    c(0,7,0) =                                    0._R_P; c(1,7,0) =                                    0._R_P
    !                    /                              ;                      /
    c(2,7,0) =                                    0._R_P; c(3,7,0) =                                    0._R_P
    !                    /                              ;                      /
    c(4,7,0) =                                    0._R_P; c(5,7,0) =                                    0._R_P
    !                    /                              ;                      /
    c(6,7,0) =                                    0._R_P; c(7,7,0) =      151567467._R_P/  3038449._R_P

    ! stencil 1
    !                    /                              ;                      /
    c(0,0,1) =      151567467._R_P/  3038449._R_P; c(1,0,1) =    -464902845._R_P/   808102._R_P
    !                    /                              ;                      /
    c(2,0,1) =    234353207._R_P/  161088._R_P; c(3,0,1) =    -2546573797._R_P/    1222381._R_P
    !                    /                              ;                      /
    c(4,0,1) =      847040497._R_P/    465789._R_P; c(5,0,1) =    -12689783695._R_P/   13147542._R_P
    !                    /                              ;                      /
    c(6,0,1) =     362054965._R_P/   1257877._R_P; c(7,0,1) =     -115902052._R_P/   3120403._R_P

    !                    /                              ;                      /
    c(0,1,1) =                                    0._R_P; c(1,1,1) =   960477863._R_P/  562021._R_P
    !                    /                              ;                      /
    c(2,1,1) =   -2039339988._R_P/   231781._R_P; c(3,1,1) =    3431063476._R_P/   269267._R_P
    !                    /                              ;                      /
    c(4,1,1) =    -3161084857._R_P/    282001._R_P; c(5,1,1) =   4037906091._R_P/  674921._R_P
    !                    /                              ;                      /
    c(6,1,1) =    -850151296._R_P/   474539._R_P; c(7,1,1) =     513945629._R_P/  2216079._R_P

    !                    /                              ;                      /
    c(0,2,1) =                                    0._R_P; c(1,2,1) =                                    0._R_P
    !                    /                              ;                      /
    c(2,2,1) =   4802121175._R_P/  418404._R_P; c(3,2,1) =      -2609137409._R_P/       77728._R_P
    !                    /                              ;                      /
    c(4,2,1) =   4919628784._R_P/   165435._R_P; c(5,2,1) =   -2029186932._R_P/   127189._R_P
    !                    /                              ;                      /
    c(6,2,1) =   2674480859._R_P/  557634._R_P; c(7,2,1) =     -724803819._R_P/    1163906._R_P

    !                    /                              ;                      /
    c(0,3,1) =                                    0._R_P; c(1,3,1) =                                    0._R_P
    !                    /                              ;                      /
    c(2,3,1) =                                    0._R_P; c(3,3,1) =     3485486425._R_P/    140912._R_P
    !                    /                              ;                      /
    c(4,3,1) =    -5435379710._R_P/    123283._R_P; c(5,3,1) =   1773946113._R_P/   74654._R_P
    !                    /                              ;                      /
    c(6,3,1) =     -1907782262._R_P/     266123._R_P; c(7,3,1) =       779780282._R_P/     835427._R_P

    !                    /                              ;                      /
    c(0,4,1) =                                    0._R_P; c(1,4,1) =                                    0._R_P
    !                    /                              ;                      /
    c(2,4,1) =                                    0._R_P; c(3,4,1) =                                    0._R_P
    !                    /                              ;                      /
    c(4,4,1) =     3163565270._R_P/    160241._R_P; c(5,4,1) =      -1674462641._R_P/      78375._R_P
    !                    /                              ;                      /
    c(6,4,1) =    2349626332._R_P/   363399._R_P; c(7,4,1) =      -1403389204._R_P/    1662883._R_P

    !                    /                              ;                      /
    c(0,5,1) =                                    0._R_P; c(1,5,1) =                                    0._R_P
    !                    /                              ;                      /
    c(2,5,1) =                                    0._R_P; c(3,5,1) =                                    0._R_P
    !                    /                              ;                      /
    c(4,5,1) =                                    0._R_P; c(5,5,1) =   3171324093._R_P/  546871._R_P
    !                    /                              ;                      /
    c(6,5,1) =   -686664647._R_P/   195106._R_P; c(7,5,1) =    281051417._R_P/  610454._R_P

    !                    /                              ;                      /
    c(0,6,1) =                                    0._R_P; c(1,6,1) =                                    0._R_P
    !                    /                              ;                      /
    c(2,6,1) =                                    0._R_P; c(3,6,1) =                                    0._R_P
    !                    /                              ;                      /
    c(4,6,1) =                                    0._R_P; c(5,6,1) =                                    0._R_P
    !                    /                              ;                      /
    c(6,6,1) =    48179335._R_P/  90019._R_P; c(7,6,1) =     -255613952._R_P/    1821943._R_P

    !                    /                              ;                      /
    c(0,7,1) =                                    0._R_P; c(1,7,1) =                                    0._R_P
    !                    /                              ;                      /
    c(2,7,1) =                                    0._R_P; c(3,7,1) =                                    0._R_P
    !                    /                              ;                      /
    c(4,7,1) =                                    0._R_P; c(5,7,1) =                                    0._R_P
    !                    /                              ;                      /
    c(6,7,1) =                                    0._R_P; c(7,7,1) =       79932001._R_P/   8679360._R_P

    ! stencil 2
    !                    /                              ;                      /
    c(0,0,2) =       79932001._R_P/   8679360._R_P; c(1,0,2) =     -655235691._R_P/    5945464._R_P
    !                    /                              ;                      /
    c(2,0,2) =     205707004._R_P/  724801._R_P; c(3,0,2) =     -559020701._R_P/    1367726._R_P
    !                    /                              ;                      /
    c(4,0,2) =      610690841._R_P/   1715763._R_P; c(5,0,2) =      -179578697._R_P/    957716._R_P
    !                    /                              ;                      /
    c(6,0,2) =     112959697._R_P/  2041527._R_P; c(7,0,2) =      -44754099._R_P/   6344939._R_P

    !                    /                              ;                      /
    c(0,1,2) =                                    0._R_P; c(1,1,2) =    403846727._R_P/  1180353._R_P
    !                    /                              ;                      /
    c(2,1,2) =    -1032899132._R_P/   571995._R_P; c(3,1,2) =     554363127._R_P/   209623._R_P
    !                    /                              ;                      /
    c(4,1,2) =      -699001320._R_P/     299911._R_P; c(5,1,2) =    324962019._R_P/  262375._R_P
    !                    /                              ;                      /
    c(6,1,2) =     -649079478._R_P/   1764673._R_P; c(7,1,2) =     129766396._R_P/  2754429._R_P

    !                    /                              ;                      /
    c(0,2,2) =                                    0._R_P; c(1,2,2) =                                    0._R_P
    !                    /                              ;                      /
    c(2,2,2) =    5814856284._R_P/  2387539._R_P; c(3,2,2) =     -1300201595._R_P/     179203._R_P
    !                    /                              ;                      /
    c(4,2,2) =    1056954815._R_P/   163259._R_P; c(5,2,2) =    -8089971196._R_P/   2329825._R_P
    !                    /                              ;                      /
    c(6,2,2) =    501175243._R_P/  482649._R_P; c(7,2,2) =     -270604594._R_P/   2024029._R_P

    !                    /                              ;                      /
    c(0,3,2) =                                    0._R_P; c(1,3,2) =                                    0._R_P
    !                    /                              ;                      /
    c(2,3,2) =                                    0._R_P; c(3,3,2) =     7318753887._R_P/    1334341._R_P
    !                    /                              ;                      /
    c(4,3,2) =    -823868037._R_P/    83150._R_P; c(5,3,2) =    4782113096._R_P/   891381._R_P
    !                    /                              ;                      /
    c(6,3,2) =      -694807489._R_P/     429931._R_P; c(7,3,2) =      430661427._R_P/   2058148._R_P

    !                    /                              ;                      /
    c(0,4,2) =                                    0._R_P; c(1,4,2) =                                    0._R_P
    !                    /                              ;                      /
    c(2,4,2) =                                    0._R_P; c(3,4,2) =                                    0._R_P
    !                    /                              ;                      /
    c(4,4,2) =      1492354285._R_P/     329872._R_P; c(5,4,2) =       -799191084._R_P/      161641._R_P
    !                    /                              ;                      /
    c(6,4,2) =     559782185._R_P/   373076._R_P; c(7,4,2) =     -114044024._R_P/    583601._R_P

    !                    /                              ;                      /
    c(0,5,2) =                                    0._R_P; c(1,5,2) =                                    0._R_P
    !                    /                              ;                      /
    c(2,5,2) =                                    0._R_P; c(3,5,2) =                                    0._R_P
    !                    /                              ;                      /
    c(4,5,2) =                                    0._R_P; c(5,5,2) =    257028097._R_P/  188691._R_P
    !                    /                              ;                      /
    c(6,5,2) =    -493139495._R_P/   592214._R_P; c(7,5,2) =     401318077._R_P/  3678649._R_P

    !                    /                              ;                      /
    c(0,6,2) =                                    0._R_P; c(1,6,2) =                                    0._R_P
    !                    /                              ;                      /
    c(2,6,2) =                                    0._R_P; c(3,6,2) =                                    0._R_P
    !                    /                              ;                      /
    c(4,6,2) =                                    0._R_P; c(5,6,2) =                                    0._R_P
    !                    /                              ;                      /
    c(6,6,2) =     629957047._R_P/  4917482._R_P; c(7,6,2) =      -141509768._R_P/   4191221._R_P

    !                    /                              ;                      /
    c(0,7,2) =                                    0._R_P; c(1,7,2) =                                    0._R_P
    !                    /                              ;                      /
    c(2,7,2) =                                    0._R_P; c(3,7,2) =                                    0._R_P
    !                    /                              ;                      /
    c(4,7,2) =                                    0._R_P; c(5,7,2) =                                    0._R_P
    !                    /                              ;                      /
    c(6,7,2) =                                    0._R_P; c(7,7,2) =       35501666._R_P/  15868715._R_P

    ! stencil 3
    !                    /                              ;                      /
    c(0,0,3) =       35501666._R_P/  15868715._R_P; c(1,0,3) =      -63831289._R_P/   2220847._R_P
    !                    /                              ;                      /
    c(2,0,3) =     268720507._R_P/  3437558._R_P; c(3,0,3) =      -134406712._R_P/    1150037._R_P
    !                    /                              ;                      /
    c(4,0,3) =       148443265._R_P/    1427854._R_P; c(5,0,3) =     -103772319._R_P/   1881526._R_P
    !                    /                              ;                      /
    c(6,0,3) =      141070919._R_P/  8713488._R_P; c(7,0,3) =       -21873377._R_P/   10764442._R_P

    !                    /                              ;                      /
    c(0,1,3) =                                    0._R_P; c(1,1,3) =     204776677._R_P/  2133916._R_P
    !                    /                              ;                      /
    c(2,1,3) =    -234383777._R_P/   435589._R_P; c(3,1,3) =     3507914221._R_P/   4258272._R_P
    !                    /                              ;                      /
    c(4,1,3) =      -311872754._R_P/    417681._R_P; c(5,1,3) =    422372886._R_P/  1050263._R_P
    !                    /                              ;                      /
    c(6,1,3) =     -386869123._R_P/   3236626._R_P; c(7,1,3) =      69576681._R_P/  4589819._R_P

    !                    /                              ;                      /
    c(0,2,3) =                                    0._R_P; c(1,2,3) =                                    0._R_P
    !                    /                              ;                      /
    c(2,2,3) =    360251831._R_P/  463656._R_P; c(3,2,3) =       -809595667._R_P/      331812._R_P
    !                    /                              ;                      /
    c(4,2,3) =    1441974426._R_P/   638695._R_P; c(5,2,3) =    -84200903._R_P/   68084._R_P
    !                    /                              ;                      /
    c(6,2,3) =    693020919._R_P/  1859333._R_P; c(7,2,3) =      -398300903._R_P/    8329274._R_P

    !                    /                              ;                      /
    c(0,3,3) =                                    0._R_P; c(1,3,3) =                                    0._R_P
    !                    /                              ;                      /
    c(2,3,3) =                                    0._R_P; c(3,3,3) =      755335167._R_P/    384508._R_P
    !                    /                              ;                      /
    c(4,3,3) =     -1353219397._R_P/    363901._R_P; c(5,3,3) =      520921076._R_P/    250961._R_P
    !                    /                              ;                      /
    c(6,3,3) =      -543724576._R_P/     855585._R_P; c(7,3,3) =       200885069._R_P/    2431769._R_P

    !                    /                              ;                      /
    c(0,4,3) =                                    0._R_P; c(1,4,3) =                                    0._R_P
    !                    /                              ;                      /
    c(2,4,3) =                                    0._R_P; c(3,4,3) =                                    0._R_P
    !                    /                              ;                      /
    c(4,4,3) =      1014659207._R_P/    563712._R_P; c(5,4,3) =      -1022198433._R_P/     498364._R_P
    !                    /                              ;                      /
    c(6,4,3) =     379000051._R_P/   592915._R_P; c(7,4,3) =      -65777185._R_P/    779772._R_P

    !                    /                              ;                      /
    c(0,5,3) =                                    0._R_P; c(1,5,3) =                                    0._R_P
    !                    /                              ;                      /
    c(2,5,3) =                                    0._R_P; c(3,5,3) =                                    0._R_P
    !                    /                              ;                      /
    c(4,5,3) =                                    0._R_P; c(5,5,3) =    789836795._R_P/  1323609._R_P
    !                    /                              ;                      /
    c(6,5,3) =    -540913157._R_P/   1426197._R_P; c(7,5,3) =     108380895._R_P/  2128121._R_P

    !                    /                              ;                      /
    c(0,6,3) =                                    0._R_P; c(1,6,3) =                                    0._R_P
    !                    /                              ;                      /
    c(2,6,3) =                                    0._R_P; c(3,6,3) =                                    0._R_P
    !                    /                              ;                      /
    c(4,6,3) =                                    0._R_P; c(5,6,3) =                                    0._R_P
    !                    /                              ;                      /
    c(6,6,3) =     358821925._R_P/  5833643._R_P; c(7,6,3) =       -39287533._R_P/    2331609._R_P

    !                    /                              ;                      /
    c(0,7,3) =                                    0._R_P; c(1,7,3) =                                    0._R_P
    !                    /                              ;                      /
    c(2,7,3) =                                    0._R_P; c(3,7,3) =                                    0._R_P
    !                    /                              ;                      /
    c(4,7,3) =                                    0._R_P; c(5,7,3) =                                    0._R_P
    !                    /                              ;                      /
    c(6,7,3) =                                    0._R_P; c(7,7,3) =       12431715._R_P/  10534253._R_P

    ! stencil 4
    !                    /                              ;                      /
    c(0,0,4) =       12431715._R_P/  10534253._R_P; c(1,0,4) =       -39287533._R_P/    2331609._R_P
    !                    /                              ;                      /
    c(2,0,4) =     108380895._R_P/  2128121._R_P; c(3,0,4) =      -65777185._R_P/    779772._R_P
    !                    /                              ;                      /
    c(4,0,4) =       200885069._R_P/    2431769._R_P; c(5,0,4) =      -398300903._R_P/    8329274._R_P
    !                    /                              ;                      /
    c(6,0,4) =      69576681._R_P/  4589819._R_P; c(7,0,4) =       -21873377._R_P/   10764442._R_P

    !                    /                              ;                      /
    c(0,1,4) =                                    0._R_P; c(1,1,4) =     358821925._R_P/  5833643._R_P
    !                    /                              ;                      /
    c(2,1,4) =    -540913157._R_P/   1426197._R_P; c(3,1,4) =     379000051._R_P/   592915._R_P
    !                    /                              ;                      /
    c(4,1,4) =      -543724576._R_P/     855585._R_P; c(5,1,4) =    693020919._R_P/  1859333._R_P
    !                    /                              ;                      /
    c(6,1,4) =     -386869123._R_P/   3236626._R_P; c(7,1,4) =      141070919._R_P/  8713488._R_P

    !                    /                              ;                      /
    c(0,2,4) =                                    0._R_P; c(1,2,4) =                                    0._R_P
    !                    /                              ;                      /
    c(2,2,4) =    789836795._R_P/  1323609._R_P; c(3,2,4) =      -1022198433._R_P/     498364._R_P
    !                    /                              ;                      /
    c(4,2,4) =      520921076._R_P/    250961._R_P; c(5,2,4) =    -84200903._R_P/   68084._R_P
    !                    /                              ;                      /
    c(6,2,4) =    422372886._R_P/  1050263._R_P; c(7,2,4) =     -103772319._R_P/   1881526._R_P

    !                    /                              ;                      /
    c(0,3,4) =                                    0._R_P; c(1,3,4) =                                    0._R_P
    !                    /                              ;                      /
    c(2,3,4) =                                    0._R_P; c(3,3,4) =      1014659207._R_P/    563712._R_P
    !                    /                              ;                      /
    c(4,3,4) =     -1353219397._R_P/    363901._R_P; c(5,3,4) =    1441974426._R_P/   638695._R_P
    !                    /                              ;                      /
    c(6,3,4) =      -311872754._R_P/    417681._R_P; c(7,3,4) =       148443265._R_P/    1427854._R_P

    !                    /                              ;                      /
    c(0,4,4) =                                    0._R_P; c(1,4,4) =                                    0._R_P
    !                    /                              ;                      /
    c(2,4,4) =                                    0._R_P; c(3,4,4) =                                    0._R_P
    !                    /                              ;                      /
    c(4,4,4) =      755335167._R_P/    384508._R_P; c(5,4,4) =       -809595667._R_P/      331812._R_P
    !                    /                              ;                      /
    c(6,4,4) =     3507914221._R_P/   4258272._R_P; c(7,4,4) =      -134406712._R_P/    1150037._R_P

    !                    /                              ;                      /
    c(0,5,4) =                                    0._R_P; c(1,5,4) =                                    0._R_P
    !                    /                              ;                      /
    c(2,5,4) =                                    0._R_P; c(3,5,4) =                                    0._R_P
    !                    /                              ;                      /
    c(4,5,4) =                                    0._R_P; c(5,5,4) =    360251831._R_P/  463656._R_P
    !                    /                              ;                      /
    c(6,5,4) =    -234383777._R_P/   435589._R_P; c(7,5,4) =     268720507._R_P/  3437558._R_P

    !                    /                              ;                      /
    c(0,6,4) =                                    0._R_P; c(1,6,4) =                                    0._R_P
    !                    /                              ;                      /
    c(2,6,4) =                                    0._R_P; c(3,6,4) =                                    0._R_P
    !                    /                              ;                      /
    c(4,6,4) =                                    0._R_P; c(5,6,4) =                                    0._R_P
    !                    /                              ;                      /
    c(6,6,4) =     204776677._R_P/  2133916._R_P; c(7,6,4) =      -63831289._R_P/   2220847._R_P

    !                    /                              ;                      /
    c(0,7,4) =                                    0._R_P; c(1,7,4) =                                    0._R_P
    !                    /                              ;                      /
    c(2,7,4) =                                    0._R_P; c(3,7,4) =                                    0._R_P
    !                    /                              ;                      /
    c(4,7,4) =                                    0._R_P; c(5,7,4) =                                    0._R_P
    !                    /                              ;                      /
    c(6,7,4) =                                    0._R_P; c(7,7,4) =       35501666._R_P/  15868715._R_P
    ! stencil 5
    !                    /                              ;                     /
    c(0,0,5) =       35501666._R_P/  15868715._R_P; c(1,0,5) =      -141509768._R_P/   4191221._R_P
    !                    /                              ;                     /
    c(2,0,5) =     401318077._R_P/  3678649._R_P; c(3,0,5) =     -114044024._R_P/    583601._R_P
    !                    /                              ;                     /
    c(4,0,5) =      430661427._R_P/   2058148._R_P; c(5,0,5) =     -270604594._R_P/   2024029._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,0,5) =     129766396._R_P/  2754429._R_P; c(7,0,5) =      -44754099._R_P/   6344939._R_P

    !                    /                              ;                     /
    c(0,1,5) =                                    0._R_P; c(1,1,5) =     629957047._R_P/  4917482._R_P
    !                    /                              ;                     /
    c(2,1,5) =    -493139495._R_P/   592214._R_P; c(3,1,5) =     559782185._R_P/   373076._R_P
    !                    /                              ;                     /
    c(4,1,5) =      -694807489._R_P/     429931._R_P; c(5,1,5) =    501175243._R_P/  482649._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,1,5) =     -649079478._R_P/   1764673._R_P; c(7,1,5) =     112959697._R_P/  2041527._R_P

    !                    /                              ;                     /
    c(0,2,5) =                                    0._R_P; c(1,2,5) =                                    0._R_P
    !                    /                              ;                     /
    c(2,2,5) =    257028097._R_P/  188691._R_P; c(3,2,5) =       -799191084._R_P/      161641._R_P
    !                    /                              ;                     /
    c(4,2,5) =    4782113096._R_P/   891381._R_P; c(5,2,5) =    -8089971196._R_P/   2329825._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,2,5) =    324962019._R_P/  262375._R_P; c(7,2,5) =      -179578697._R_P/    957716._R_P

    !                    /                              ;                     /
    c(0,3,5) =                                    0._R_P; c(1,3,5) =                                    0._R_P
    !                    /                              ;                     /
    c(2,3,5) =                                    0._R_P; c(3,3,5) =      1492354285._R_P/     329872._R_P
    !                    /                              ;                     /
    c(4,3,5) =    -823868037._R_P/    83150._R_P; c(5,3,5) =    1056954815._R_P/   163259._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,3,5) =      -699001320._R_P/     299911._R_P; c(7,3,5) =      610690841._R_P/   1715763._R_P

    !                    /                              ;                     /
    c(0,4,5) =                                    0._R_P; c(1,4,5) =                                    0._R_P
    !                    /                              ;                     /
    c(2,4,5) =                                    0._R_P; c(3,4,5) =                                    0._R_P
    !                    /                              ;                     /
    c(4,4,5) =     7318753887._R_P/    1334341._R_P; c(5,4,5) =     -1300201595._R_P/     179203._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,4,5) =     554363127._R_P/   209623._R_P; c(7,4,5) =     -559020701._R_P/    1367726._R_P

    !                    /                              ;                     /
    c(0,5,5) =                                    0._R_P; c(1,5,5) =                                    0._R_P
    !                    /                              ;                     /
    c(2,5,5) =                                    0._R_P; c(3,5,5) =                                    0._R_P
    !                    /                              ;                     /
    c(4,5,5) =                                    0._R_P; c(5,5,5) =    5814856284._R_P/  2387539._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,5,5) =    -1032899132._R_P/   571995._R_P; c(7,5,5) =     205707004._R_P/  724801._R_P

    !                    /                              ;                     /
    c(0,6,5) =                                    0._R_P; c(1,6,5) =                                    0._R_P
    !                    /                              ;                     /
    c(2,6,5) =                                    0._R_P; c(3,6,5) =                                    0._R_P
    !                    /                              ;                     /
    c(4,6,5) =                                    0._R_P; c(5,6,5) =                                    0._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,6,5) =    403846727._R_P/  1180353._R_P; c(7,6,5) =     -655235691._R_P/    5945464._R_P

    !                    /                              ;                     /
    c(0,7,5) =                                    0._R_P; c(1,7,5) =                                    0._R_P
    !                    /                              ;                     /
    c(2,7,5) =                                    0._R_P; c(3,7,5) =                                    0._R_P
    !                    /                              ;                     /
    c(4,7,5) =                                    0._R_P; c(5,7,5) =                                    0._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,7,5) =                                    0._R_P; c(7,7,5) =       79932001._R_P/   8679360._R_P

    ! stencil 6
    !                    /                              ;                     /
    c(0,0,6) =       79932001._R_P/   8679360._R_P; c(1,0,6) =     -255613952._R_P/    1821943._R_P
    !                    /                              ;                     /
    c(2,0,6) =    281051417._R_P/  610454._R_P; c(3,0,6) =      -1403389204._R_P/    1662883._R_P
    !                    /                              ;                     /
    c(4,0,6) =       779780282._R_P/     835427._R_P; c(5,0,6) =     -724803819._R_P/    1163906._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,0,6) =     513945629._R_P/  2216079._R_P; c(7,0,6) =     -115902052._R_P/   3120403._R_P

    !                    /                              ;                     /
    c(0,1,6) =                                    0._R_P; c(1,1,6) =    48179335._R_P/  90019._R_P
    !                    /                              ;                     /
    c(2,1,6) =   -686664647._R_P/   195106._R_P; c(3,1,6) =    2349626332._R_P/   363399._R_P
    !                    /                              ;                     /
    c(4,1,6) =     -1907782262._R_P/     266123._R_P; c(5,1,6) =   2674480859._R_P/  557634._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,1,6) =    -850151296._R_P/   474539._R_P; c(7,1,6) =     362054965._R_P/   1257877._R_P

    !                    /                              ;                     /
    c(0,2,6) =                                    0._R_P; c(1,2,6) =                                    0._R_P
    !                    /                              ;                     /
    c(2,2,6) =   3171324093._R_P/  546871._R_P; c(3,2,6) =      -1674462641._R_P/      78375._R_P
    !                    /                              ;                     /
    c(4,2,6) =   1773946113._R_P/   74654._R_P; c(5,2,6) =   -2029186932._R_P/   127189._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,2,6) =   4037906091._R_P/  674921._R_P; c(7,2,6) =    -12689783695._R_P/   13147542._R_P

    !                    /                              ;                     /
    c(0,3,6) =                                    0._R_P; c(1,3,6) =                                    0._R_P
    !                    /                              ;                     /
    c(2,3,6) =                                    0._R_P; c(3,3,6) =     3163565270._R_P/    160241._R_P
    !                    /                              ;                     /
    c(4,3,6) =    -5435379710._R_P/    123283._R_P; c(5,3,6) =   4919628784._R_P/   165435._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,3,6) =    -3161084857._R_P/    282001._R_P; c(7,3,6) =      847040497._R_P/    465789._R_P

    !                    /                              ;                     /
    c(0,4,6) =                                    0._R_P; c(1,4,6) =                                    0._R_P
    !                    /                              ;                     /
    c(2,4,6) =                                    0._R_P; c(3,4,6) =                                    0._R_P
    !                    /                              ;                     /
    c(4,4,6) =     3485486425._R_P/    140912._R_P; c(5,4,6) =      -2609137409._R_P/       77728._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,4,6) =    3431063476._R_P/   269267._R_P; c(7,4,6) =    -2546573797._R_P/    1222381._R_P

    !                    /                              ;                     /
    c(0,5,6) =                                    0._R_P; c(1,5,6) =                                    0._R_P
    !                    /                              ;                     /
    c(2,5,6) =                                    0._R_P; c(3,5,6) =                                    0._R_P
    !                    /                              ;                     /
    c(4,5,6) =                                    0._R_P; c(5,5,6) =   4802121175._R_P/  418404._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,5,6) =   -2039339988._R_P/   231781._R_P; c(7,5,6) =    234353207._R_P/  161088._R_P

    !                    /                              ;                     /
    c(0,6,6) =                                    0._R_P; c(1,6,6) =                                    0._R_P
    !                    /                              ;                     /
    c(2,6,6) =                                    0._R_P; c(3,6,6) =                                    0._R_P
    !                    /                              ;                     /
    c(4,6,6) =                                    0._R_P; c(5,6,6) =                                    0._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,6,6) =   960477863._R_P/  562021._R_P; c(7,6,6) =    -464902845._R_P/   808102._R_P

    !                    /                              ;                     /
    c(0,7,6) =                                    0._R_P; c(1,7,6) =                                    0._R_P
    !                    /                              ;                     /
    c(2,7,6) =                                    0._R_P; c(3,7,6) =                                    0._R_P
    !                    /                              ;                     /
    c(4,7,6) =                                    0._R_P; c(5,7,6) =                                    0._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,7,6) =                                    0._R_P; c(7,7,6) =      151567467._R_P/  3038449._R_P

    ! stencil 7
    !                    /                              ;                     /
    c(0,0,7) =      151567467._R_P/  3038449._R_P; c(1,0,7) =    -508083143._R_P/   667663._R_P
    !                    /                              ;                     /
    c(2,0,7) =    4932843539._R_P/   1968706._R_P; c(3,0,7) =    -1774088813._R_P/    383858._R_P
    !                    /                              ;                     /
    c(4,0,7) =    1168472761._R_P/   226223._R_P; c(5,0,7) =    -2034860005._R_P/   580787._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,0,7) =    1606637628._R_P/  1200199._R_P; c(7,0,7) =     -167817292._R_P/   753123._R_P

    !                    /                              ;                     /
    c(0,1,7) =                                    0._R_P; c(1,1,7) =   1285415788._R_P/  442547._R_P
    !                    /                              ;                     /
    c(2,1,7) =   -1307164757._R_P/   68276._R_P; c(3,1,7) =    12211598186._R_P/   345407._R_P
    !                    /                              ;                     /
    c(4,1,7) =    -3946887082._R_P/    99757._R_P; c(5,1,7) =   4477231643._R_P/  166549._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,1,7) =   -8115803171._R_P/   788565._R_P; c(7,1,7) =    1730988313._R_P/  1007913._R_P

    !                    /                              ;                     /
    c(0,2,7) =                                    0._R_P; c(1,2,7) =                                    0._R_P
    !                    /                              ;                     /
    c(2,2,7) =   5633451919._R_P/  178362._R_P; c(3,2,7) =     -2087501693._R_P/      17871._R_P
    !                    /                              ;                     /
    c(4,2,7) =   7936751861._R_P/   60613._R_P; c(5,2,7) =  -9679034365._R_P/   108568._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,2,7) =  3436464517._R_P/  100426._R_P; c(7,2,7) =    -6701525420._R_P/    1169941._R_P

    !                    /                              ;                     /
    c(0,3,7) =                                    0._R_P; c(1,3,7) =                                    0._R_P
    !                    /                              ;                     /
    c(2,3,7) =                                    0._R_P; c(3,3,7) =    15685259234._R_P/    144989._R_P
    !                    /                              ;                     /
    c(4,3,7) =   -10453320754._R_P/    43009._R_P; c(5,3,7) =   2354499851._R_P/   14191._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,3,7) =     -2650855638._R_P/      41489._R_P; c(7,3,7) =     1191775685._R_P/    110969._R_P

    !                    /                              ;                     /
    c(0,4,7) =                                    0._R_P; c(1,4,7) =                                    0._R_P
    !                    /                              ;                     /
    c(2,4,7) =                                    0._R_P; c(3,4,7) =                                    0._R_P
    !                    /                              ;                     /
    c(4,4,7) =     5383551615._R_P/     39332._R_P; c(5,4,7) =    -4461330800._R_P/     23793._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,4,7) =   2653665219._R_P/   36590._R_P; c(7,4,7) =    -1384199219._R_P/    112909._R_P

    !                    /                              ;                     /
    c(0,5,7) =                                    0._R_P; c(1,5,7) =                                    0._R_P
    !                    /                              ;                     /
    c(2,5,7) =                                    0._R_P; c(3,5,7) =                                    0._R_P
    !                    /                              ;                     /
    c(4,5,7) =                                    0._R_P; c(5,5,7) =  3382169379._R_P/  52433._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,5,7) =  -6783346413._R_P/   135128._R_P; c(7,5,7) =    1512171950._R_P/   176773._R_P

    !                    /                              ;                     /
    c(0,6,7) =                                    0._R_P; c(1,6,7) =                                    0._R_P
    !                    /                              ;                     /
    c(2,6,7) =                                    0._R_P; c(3,6,7) =                                    0._R_P
    !                    /                              ;                     /
    c(4,6,7) =                                    0._R_P; c(5,6,7) =                                    0._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,6,7) =   5230798390._R_P/  531001._R_P; c(7,6,7) =    -1353623375._R_P/    398213._R_P

    !                    /                              ;                     /
    c(0,7,7) =                                    0._R_P; c(1,7,7) =                                    0._R_P
    !                    /                              ;                     /
    c(2,7,7) =                                    0._R_P; c(3,7,7) =                                    0._R_P
    !                    /                              ;                     /
    c(4,7,7) =                                    0._R_P; c(5,7,7) =                                    0._R_P
    !                  (i-4)*(i-5)                      ;
    c(6,7,7) =                                    0._R_P; c(7,7,7) =     561955582._R_P/  1878967._R_P
  case(9) ! 17th order
    ! stencil 0
    !                    /                               ;                     /
    c(0,0,0) =    191906863._R_P/ 270061._R_P;c(1,0,0) =   -1291706883._R_P/ 137012._R_P
    !                    /                               ;                     /
    c(2,0,0) =  1051885279._R_P/37394._R_P;c(3,0,0) = -6519672839._R_P/ 133134._R_P
    !                    /                               ;                     /
    c(4,0,0) =    8028408627._R_P/  148285._R_P;c(5,0,0) = -12858081715._R_P/331389._R_P
    !                    /                               ;                     /
    c(6,0,0) =  7116193241._R_P/405236._R_P;c(7,0,0) =  -1382011106._R_P/301683._R_P
    !                    /                               ;                     /
    c(8,0,0) =    380112881._R_P/ 721737._R_P

    !                    /                               ;                     /
    c(0,1,0) =                                     0._R_P;c(1,1,0) =   2789709824._R_P/ 87891._R_P
    !                    /                               ;                     /
    c(2,1,0) = -2523726139._R_P/ 13197._R_P;c(3,1,0) = 10624327325._R_P/ 31707._R_P
    !                    /                               ;                     /
    c(4,1,0) = -14121568547._R_P/ 37942._R_P;c(5,1,0) = 13666821827._R_P/ 51060._R_P
    !                    /                               ;                     /
    c(6,1,0) = -7097325924._R_P/ 58429._R_P;c(7,1,0) =    962141663._R_P/   30298._R_P
    !                    /                               ;                     /
    c(8,1,0) =  -1039356853._R_P/284187._R_P

    !                    /                               ;                     /
    c(0,2,0) =                                     0._R_P;c(1,2,0) =                                     0._R_P
    !                    /                               ;                     /
    c(2,2,0) =   958711850795._R_P/  3306139._R_P;c(3,2,0) = -32612776236._R_P/  31939._R_P
    !                    /                               ;                     /
    c(4,2,0) =    29334155111._R_P/    25771._R_P;c(5,2,0) = -13491549889._R_P/  16436._R_P
    !                    /                               ;                     /
    c(6,2,0) =  8640690184._R_P/  23145._R_P;c(7,2,0) = -7469836609._R_P/ 76401._R_P
    !                    /                               ;                     /
    c(8,2,0) =  2160095091._R_P/191558._R_P

    !                    /                               ;                     /
    c(0,3,0) =                                     0._R_P;c(1,3,0) =                                     0._R_P
    !                    /                               ;                     /
    c(2,3,0) =                                     0._R_P;c(3,3,0) = 26479157148._R_P/ 29351._R_P
    !                    /                               ;                     /
    c(4,3,0) =  -34046474687._R_P/   16880._R_P;c(5,3,0) =  25425670807._R_P/  17442._R_P
    !                    /                               ;                     /
    c(6,3,0) = -13534679320._R_P/  20379._R_P;c(7,3,0) = 8534140303._R_P/ 48995._R_P
    !                    /                               ;                     /
    c(8,3,0) = -16400242834._R_P/815393._R_P

    !                    /                               ;                     /
    c(0,4,0) =                                     0._R_P;c(1,4,0) =                                     0._R_P
    !                    /                               ;                     /
    c(2,4,0) =                                     0._R_P;c(3,4,0) =                                     0._R_P
    !                    /                               ;                     /
    c(4,4,0) =   7211727349._R_P/   6383._R_P;c(5,4,0) =  -32852743324._R_P/   20081._R_P
    !                    /                               ;                     /
    c(6,4,0) =    9817971019._R_P/    13153._R_P;c(7,4,0) = -29831101642._R_P/ 152201._R_P
    !                    /                               ;                     /
    c(8,4,0) =   1211629703._R_P/  53483._R_P

    !                    /                               ;                     /
    c(0,5,0) =                                     0._R_P;c(1,5,0) =                                     0._R_P
    !                    /                               ;                     /
    c(2,5,0) =                                     0._R_P;c(3,5,0) =                                     0._R_P
    !                    /                               ;                     /
    c(4,5,0) =                                     0._R_P;c(5,5,0) = 181942554161._R_P/ 306771._R_P
    !                    /                               ;                     /
    c(6,5,0) = -10120501295._R_P/  18678._R_P;c(7,5,0) =  6203677189._R_P/ 43561._R_P
    !                    /                               ;                     /
    c(8,5,0) =   -800361473._R_P/  48582._R_P

    !                    /                               ;                     /
    c(0,6,0) =                                     0._R_P;c(1,6,0) =                                     0._R_P
    !                    /                               ;                     /
    c(2,6,0) =                                     0._R_P;c(3,6,0) =                                     0._R_P
    !                    /                               ;                     /
    c(4,6,0) =                                     0._R_P;c(5,6,0) =                                     0._R_P
    !                    /                               ;                     /
    c(6,6,0) =   9873545067._R_P/  79705._R_P;c(7,6,0) = -5910597075._R_P/ 90694._R_P
    !                    /                               ;                     /
    c(8,6,0) =   2005851423._R_P/265880._R_P

    !                    /                               ;                     /
    c(0,7,0) =                                     0._R_P;c(1,7,0) =                                     0._R_P
    !                    /                               ;                     /
    c(2,7,0) =                                     0._R_P;c(3,7,0) =                                     0._R_P
    !                    /                               ;                     /
    c(4,7,0) =                                     0._R_P;c(5,7,0) =                                     0._R_P
    !                    /                               ;                     /
    c(6,7,0) =                                     0._R_P;c(7,7,0) =  1207396129._R_P/140764._R_P
    !                    /                               ;                     /
    c(8,7,0) =   -989259649._R_P/ 497859._R_P

    !                    /                               ;                     /
    c(0,8,0) =                                     0._R_P;c(1,8,0) =                                     0._R_P
    !                    /                               ;                     /
    c(2,8,0) =                                     0._R_P;c(3,8,0) =                                     0._R_P
    !                    /                               ;                     /
    c(4,8,0) =                                     0._R_P;c(5,8,0) =                                     0._R_P
    !                    /                               ;                     /
    c(6,8,0) =                                     0._R_P;c(7,8,0) =                                     0._R_P
    !                    /                               ;                     /
    c(8,8,0) =     23000337._R_P/ 199768._R_P

    ! stencil 1
    !                    /                               ;                     /
    c(0,0,1) =     23000337._R_P/ 199768._R_P;c(1,0,1) =   -1605498941._R_P/ 1038640._R_P
    !                    /                               ;                     /
    c(2,0,1) =   1919279425._R_P/ 414313._R_P;c(3,0,1) = -351689199._R_P/43600._R_P
    !                    /                               ;                     /
    c(4,0,1) =   2318146475._R_P/ 260443._R_P;c(5,0,1) =  -1432715713._R_P/225284._R_P
    !                    /                               ;                     /
    c(6,0,1) =   1206026846._R_P/420471._R_P;c(7,0,1) =     -433682386._R_P/  581703._R_P
    !                    /                               ;                     /
    c(8,0,1) =    192493416._R_P/2253847._R_P

    !                    /                               ;                     /
    c(0,1,1) =                                     0._R_P;c(1,1,1) =   8788336457._R_P/1659246._R_P
    !                    /                               ;                     /
    c(2,1,1) = -6349489117._R_P/ 197436._R_P;c(3,1,1) =  17759778441._R_P/ 314408._R_P
    !                    /                               ;                     /
    c(4,1,1) =  -2463944763._R_P/ 39286._R_P;c(5,1,1) =  2631734550._R_P/ 58459._R_P
    !                    /                               ;                     /
    c(6,1,1) =  -684405583._R_P/ 33590._R_P;c(7,1,1) =     1632642660._R_P/   307433._R_P
    !                    /                               ;                     /
    c(8,1,1) =   -759205271._R_P/1245236._R_P

    !                    /                               ;                     /
    c(0,2,1) =                                     0._R_P;c(1,2,1) =                                     0._R_P
    !                    /                               ;                     /
    c(2,2,1) =    138686396638._R_P/  2813507._R_P;c(3,2,1) =  -12258216466._R_P/  70285._R_P
    !                    /                               ;                     /
    c(4,2,1) =     8450768743._R_P/    43407._R_P;c(5,2,1) =  -30871077827._R_P/   220014._R_P
    !                    /                               ;                     /
    c(6,2,1) =   2904329890._R_P/  45589._R_P;c(7,2,1) =  -2519869819._R_P/ 151381._R_P
    !                    /                               ;                     /
    c(8,2,1) =   2064497172._R_P/1078127._R_P

    !                    /                               ;                     /
    c(0,3,1) =                                     0._R_P;c(1,3,1) =                                     0._R_P
    !                    /                               ;                     /
    c(2,3,1) =                                     0._R_P;c(3,3,1) =  7222761881._R_P/ 46553._R_P
    !                    /                               ;                     /
    c(4,3,1) =  -21436202114._R_P/  61611._R_P;c(5,3,1) =  21903079582._R_P/  87043._R_P
    !                    /                               ;                     /
    c(6,3,1) =  -5737609802._R_P/  50081._R_P;c(7,3,1) =  2675355119._R_P/ 89174._R_P
    !                    /                               ;                     /
    c(8,3,1) =  -1275601375._R_P/368936._R_P

    !                    /                               ;                     /
    c(0,4,1) =                                     0._R_P;c(1,4,1) =                                     0._R_P
    !                    /                               ;                     /
    c(2,4,1) =                                     0._R_P;c(3,4,1) =                                     0._R_P
    !                    /                               ;                     /
    c(4,4,1) =   5232843359._R_P/   26730._R_P;c(5,4,1) =  -32956224478._R_P/  116041._R_P
    !                    /                               ;                     /
    c(6,4,1) =     4693138545._R_P/    36209._R_P;c(7,4,1) =  -5136703769._R_P/ 151046._R_P
    !                    /                               ;                     /
    c(8,4,1) =    1990119523._R_P/ 506979._R_P

    !                    /                               ;                     /
    c(0,5,1) =                                     0._R_P;c(1,5,1) =                                     0._R_P
    !                    /                               ;                     /
    c(2,5,1) =                                     0._R_P;c(3,5,1) =                                     0._R_P
    !                    /                               ;                     /
    c(4,5,1) =                                     0._R_P;c(5,5,1) =  10194856899._R_P/ 98734._R_P
    !                    /                               ;                     /
    c(6,5,1) =  -7652084383._R_P/  81028._R_P;c(7,5,1) =   1696424402._R_P/ 68349._R_P
    !                    /                               ;                     /
    c(8,5,1) =  -557744521._R_P/194407._R_P

    !                    /                               ;                     /
    c(0,6,1) =                                     0._R_P;c(1,6,1) =                                     0._R_P
    !                    /                               ;                     /
    c(2,6,1) =                                     0._R_P;c(3,6,1) =                                     0._R_P
    !                    /                               ;                     /
    c(4,6,1) =                                     0._R_P;c(5,6,1) =                                     0._R_P
    !                    /                               ;                     /
    c(6,6,1) =    3171898228._R_P/  146643._R_P;c(7,6,1) =  -1486183058._R_P/ 130527._R_P
    !                    /                               ;                     /
    c(8,6,1) =   1414733955._R_P/1073627._R_P

    !                    /                               ;                     /
    c(0,7,1) =                                     0._R_P;c(1,7,1) =                                     0._R_P
    !                    /                               ;                     /
    c(2,7,1) =                                     0._R_P;c(3,7,1) =                                     0._R_P
    !                    /                               ;                     /
    c(4,7,1) =                                     0._R_P;c(5,7,1) =                                     0._R_P
    !                    /                               ;                     /
    c(6,7,1) =                                     0._R_P;c(7,7,1) =    550334507._R_P/ 366830._R_P
    !                    /                               ;                     /
    c(8,7,1) =    -296572045._R_P/ 853161._R_P

    !                    /                               ;                     /
    c(0,8,1) =                                     0._R_P;c(1,8,1) =                                     0._R_P
    !                    /                               ;                     /
    c(2,8,1) =                                     0._R_P;c(3,8,1) =                                     0._R_P
    !                    /                               ;                     /
    c(4,8,1) =                                     0._R_P;c(5,8,1) =                                     0._R_P
    !                    /                               ;                     /
    c(6,8,1) =                                     0._R_P;c(7,8,1) =                                     0._R_P
    !                    /                               ;                     /
    c(8,8,1) =      36409563._R_P/ 1806520._R_P

    ! stencil 2
    !                    /                               ;                     /
    c(0,0,2) =      36409563._R_P/ 1806520._R_P;c(1,0,2) =     -699447262._R_P/  2521667._R_P
    !                    /                               ;                     /
    c(2,0,2) =   277579576._R_P/329887._R_P;c(3,0,2) =  -289784372._R_P/196989._R_P
    !                    /                               ;                     /
    c(4,0,2) =    306856831._R_P/ 189251._R_P;c(5,0,2) =  -61463934._R_P/53285._R_P
    !                    /                               ;                     /
    c(6,0,2) =    688214053._R_P/1331147._R_P;c(7,0,2) =   -173397370._R_P/1299717._R_P
    !                    /                               ;                     /
    c(8,0,2) =     265338548._R_P/17495633._R_P

    !                    /                               ;                     /
    c(0,1,2) =                                     0._R_P;c(1,1,2) =   526012837._R_P/537300._R_P
    !                    /                               ;                     /
    c(2,1,2) =  -1651888798._R_P/ 273307._R_P;c(3,1,2) =   2363787227._R_P/ 220958._R_P
    !                    /                               ;                     /
    c(4,1,2) =  -10107954583._R_P/ 849559._R_P;c(5,1,2) =   5241495620._R_P/ 615127._R_P
    !                    /                               ;                     /
    c(6,1,2) =  -2367490577._R_P/ 616772._R_P;c(7,1,2) =      127754174._R_P/   128481._R_P
    !                    /                               ;                     /
    c(8,1,2) =     -264553111._R_P/  2333462._R_P

    !                    /                               ;                     /
    c(0,2,2) =                                     0._R_P;c(1,2,2) =                                     0._R_P
    !                    /                               ;                     /
    c(2,2,2) =    3248190394._R_P/  343067._R_P;c(3,2,2) =  -2028942806._R_P/  59843._R_P
    !                    /                               ;                     /
    c(4,2,2) =      1334723167._R_P/    35090._R_P;c(5,2,2) =  -765629878._R_P/  27919._R_P
    !                    /                               ;                     /
    c(6,2,2) =   2097415117._R_P/  168915._R_P;c(7,2,2) =  -676787627._R_P/ 209575._R_P
    !                    /                               ;                     /
    c(8,2,2) =    383212815._R_P/1037536._R_P

    !                    /                               ;                     /
    c(0,3,2) =                                     0._R_P;c(1,3,2) =                                     0._R_P
    !                    /                               ;                     /
    c(2,3,2) =                                     0._R_P;c(3,3,2) =   2631362108._R_P/ 85845._R_P
    !                    /                               ;                     /
    c(4,3,2) =  -4882065990._R_P/  70417._R_P;c(5,3,2) =   3655479387._R_P/  72668._R_P
    !                    /                               ;                     /
    c(6,3,2) =   -2468363819._R_P/   107827._R_P;c(7,3,2) =   1268411423._R_P/ 212206._R_P
    !                    /                               ;                     /
    c(8,3,2) =   -427576737._R_P/623480._R_P

    !                    /                               ;                     /
    c(0,4,2) =                                     0._R_P;c(1,4,2) =                                     0._R_P
    !                    /                               ;                     /
    c(2,4,2) =                                     0._R_P;c(3,4,2) =                                     0._R_P
    !                    /                               ;                     /
    c(4,4,2) =    11322353265._R_P/   286802._R_P;c(5,4,2) =  -7546651472._R_P/  130969._R_P
    !                    /                               ;                     /
    c(6,4,2) =      451561861._R_P/    17139._R_P;c(7,4,2) =   -2267814051._R_P/ 328385._R_P
    !                    /                               ;                     /
    c(8,4,2) =    537364516._R_P/ 676097._R_P

    !                    /                               ;                     /
    c(0,5,2) =                                     0._R_P;c(1,5,2) =                                     0._R_P
    !                    /                               ;                     /
    c(2,5,2) =                                     0._R_P;c(3,5,2) =                                     0._R_P
    !                    /                               ;                     /
    c(4,5,2) =                                     0._R_P;c(5,5,2) =   3256858005._R_P/ 154108._R_P
    !                    /                               ;                     /
    c(6,5,2) =   -5961122741._R_P/  307109._R_P;c(7,5,2) =   982680142._R_P/ 192447._R_P
    !                    /                               ;                     /
    c(8,5,2) =   -823497572._R_P/1397105._R_P

    !                    /                               ;                     /
    c(0,6,2) =                                     0._R_P;c(1,6,2) =                                     0._R_P
    !                    /                               ;                     /
    c(2,6,2) =                                     0._R_P;c(3,6,2) =                                     0._R_P
    !                    /                               ;                     /
    c(4,6,2) =                                     0._R_P;c(5,6,2) =                                     0._R_P
    !                    /                               ;                     /
    c(6,6,2) =     2952652193._R_P/  659941._R_P;c(7,6,2) =   -1883344606._R_P/ 797417._R_P
    !                    /                               ;                     /
    c(8,6,2) =     329649921._R_P/ 1205744._R_P

    !                    /                               ;                     /
    c(0,7,2) =                                     0._R_P;c(1,7,2) =                                     0._R_P
    !                    /                               ;                     /
    c(2,7,2) =                                     0._R_P;c(3,7,2) =                                     0._R_P
    !                    /                               ;                     /
    c(4,7,2) =                                     0._R_P;c(5,7,2) =                                     0._R_P
    !                    /                               ;                     /
    c(6,7,2) =                                     0._R_P;c(7,7,2) =    267692197._R_P/856297._R_P
    !                    /                               ;                     /
    c(8,7,2) =     -178701734._R_P/  2462661._R_P

    !                    /                               ;                     /
    c(0,8,2) =                                     0._R_P;c(1,8,2) =                                     0._R_P
    !                    /                               ;                     /
    c(2,8,2) =                                     0._R_P;c(3,8,2) =                                     0._R_P
    !                    /                               ;                     /
    c(4,8,2) =                                     0._R_P;c(5,8,2) =                                     0._R_P
    !                    /                               ;                     /
    c(6,8,2) =                                     0._R_P;c(7,8,2) =                                     0._R_P
    !                    /                               ;                     /
    c(8,8,2) =       14225607._R_P/ 3370285._R_P

    ! stencil 3
    !                    /                               ;                     /
    c(0,0,3) =       14225607._R_P/ 3370285._R_P;c(1,0,3) =     -186193587._R_P/ 3061888._R_P
    !                    /                               ;                     /
    c(2,0,3) =    103779883._R_P/544689._R_P;c(3,0,3) =    -597649141._R_P/  1759029._R_P
    !                    /                               ;                     /
    c(4,0,3) =     348597468._R_P/  922523._R_P;c(5,0,3) =   -709458479._R_P/2638758._R_P
    !                    /                               ;                     /
    c(6,0,3) =    184615935._R_P/1542601._R_P;c(7,0,3) =    -417266048._R_P/13678797._R_P
    !                    /                               ;                     /
    c(8,0,3) =      33222819._R_P/ 9738314._R_P

    !                    /                               ;                     /
    c(0,1,3) =                                     0._R_P;c(1,1,3) =    308180301._R_P/1366333._R_P
    !                    /                               ;                     /
    c(2,1,3) =   -522065981._R_P/ 360998._R_P;c(3,1,3) =   5590654438._R_P/ 2129495._R_P
    !                    /                               ;                     /
    c(4,1,3) =   -787874261._R_P/ 266082._R_P;c(5,1,3) =   1034492709._R_P/ 485618._R_P
    !                    /                               ;                     /
    c(6,1,3) =   -931274285._R_P/ 973468._R_P;c(7,1,3) =      544135101._R_P/   2215768._R_P
    !                    /                               ;                     /
    c(8,1,3) =    -243832589._R_P/8827552._R_P

    !                    /                               ;                     /
    c(0,2,3) =                                     0._R_P;c(1,2,3) =                                     0._R_P
    !                    /                               ;                     /
    c(2,2,3) =     2349998749._R_P/  992475._R_P;c(3,2,3) =   -3054791233._R_P/  349036._R_P
    !                    /                               ;                     /
    c(4,2,3) =      966000775._R_P/    96443._R_P;c(5,2,3) =   -828515195._R_P/  113623._R_P
    !                    /                               ;                     /
    c(6,2,3) =    1033739711._R_P/  312683._R_P;c(7,2,3) =   -767075415._R_P/ 896921._R_P
    !                    /                               ;                     /
    c(8,2,3) =    83373698._R_P/861333._R_P

    !                    /                               ;                     /
    c(0,3,3) =                                     0._R_P;c(1,3,3) =                                     0._R_P
    !                    /                               ;                     /
    c(2,3,3) =                                     0._R_P;c(3,3,3) =   1879971092._R_P/ 228557._R_P
    !                    /                               ;                     /
    c(4,3,3) =    -305554133._R_P/   15991._R_P;c(5,3,3) =    3662929022._R_P/  260087._R_P
    !                    /                               ;                     /
    c(6,3,3) =   -295058921._R_P/  45739._R_P;c(7,3,3) =   654146656._R_P/ 388723._R_P
    !                    /                               ;                     /
    c(8,3,3) =   -135160981._R_P/704829._R_P

    !                    /                               ;                     /
    c(0,4,3) =                                     0._R_P;c(1,4,3) =                                     0._R_P
    !                    /                               ;                     /
    c(2,4,3) =                                     0._R_P;c(3,4,3) =                                     0._R_P
    !                    /                               ;                     /
    c(4,4,3) =     1548885060._R_P/   137633._R_P;c(5,4,3) =    -8099595796._R_P/   482187._R_P
    !                    /                               ;                     /
    c(6,4,3) =      1581790037._R_P/    203396._R_P;c(7,4,3) =   -6738238495._R_P/ 3291754._R_P
    !                    /                               ;                     /
    c(8,4,3) =      85841095._R_P/  365273._R_P

    !                    /                               ;                     /
    c(0,5,3) =                                     0._R_P;c(1,5,3) =                                     0._R_P
    !                    /                               ;                     /
    c(2,5,3) =                                     0._R_P;c(3,5,3) =                                     0._R_P
    !                    /                               ;                     /
    c(4,5,3) =                                     0._R_P;c(5,5,3) =  4054421226._R_P/ 639143._R_P
    !                    /                               ;                     /
    c(6,5,3) =   -628691758._R_P/  105883._R_P;c(7,5,3) =   855538459._R_P/ 542278._R_P
    !                    /                               ;                     /
    c(8,5,3) =    -185363617._R_P/ 1015232._R_P

    !                    /                               ;                     /
    c(0,6,3) =                                     0._R_P;c(1,6,3) =                                     0._R_P
    !                    /                               ;                     /
    c(2,6,3) =                                     0._R_P;c(3,6,3) =                                     0._R_P
    !                    /                               ;                     /
    c(4,6,3) =                                     0._R_P;c(5,6,3) =                                     0._R_P
    !                    /                               ;                     /
    c(6,6,3) =     2253530669._R_P/  1605103._R_P;c(7,6,3) =   -491966393._R_P/ 653081._R_P
    !                    /                               ;                     /
    c(8,6,3) =    67366110._R_P/766169._R_P

    !                    /                               ;                     /
    c(0,7,3) =                                     0._R_P;c(1,7,3) =                                     0._R_P
    !                    /                               ;                     /
    c(2,7,3) =                                     0._R_P;c(3,7,3) =                                     0._R_P
    !                    /                               ;                     /
    c(4,7,3) =                                     0._R_P;c(5,7,3) =                                     0._R_P
    !                    /                               ;                     /
    c(6,7,3) =                                     0._R_P;c(7,7,3) =    193935861._R_P/1901234._R_P
    !                    /                               ;                     /
    c(8,7,3) =     -28933143._R_P/ 1204235._R_P

    !                    /                               ;                     /
    c(0,8,3) =                                     0._R_P;c(1,8,3) =                                     0._R_P
    !                    /                               ;                     /
    c(2,8,3) =                                     0._R_P;c(3,8,3) =                                     0._R_P
    !                    /                               ;                     /
    c(4,8,3) =                                     0._R_P;c(5,8,3) =                                     0._R_P
    !                    /                               ;                     /
    c(6,8,3) =                                     0._R_P;c(7,8,3) =                                     0._R_P
    !                    /                               ;                     /
    c(8,8,3) =       25595175._R_P/ 17925332._R_P

    ! stencil 4
    !                    /                               ;                     /
    c(0,0,4) =       25595175._R_P/ 17925332._R_P;c(1,0,4) =     -471882251._R_P/ 21169910._R_P
    !                    /                               ;                     /
    c(2,0,4) =     48978927._R_P/ 651442._R_P;c(3,0,4) =   -81991005._R_P/573014._R_P
    !                    /                               ;                     /
    c(4,0,4) =     323192477._R_P/ 1923068._R_P;c(5,0,4) =   -247486780._R_P/1982753._R_P
    !                    /                               ;                     /
    c(6,0,4) =     179193514._R_P/3127239._R_P;c(7,0,4) =     -42281552._R_P/ 2841263._R_P
    !                    /                               ;                     /
    c(8,0,4) =      21701959._R_P/12951510._R_P

    !                    /                               ;                     /
    c(0,1,4) =                                     0._R_P;c(1,1,4) =    206821378._R_P/2319277._R_P
    !                    /                               ;                     /
    c(2,1,4) =   -257255959._R_P/ 418532._R_P;c(3,1,4) =    1066785823._R_P/ 895146._R_P
    !                    /                               ;                     /
    c(4,1,4) =   -659953893._R_P/ 463955._R_P;c(5,1,4) =    889068808._R_P/ 829823._R_P
    !                    /                               ;                     /
    c(6,1,4) =   -379006664._R_P/ 761061._R_P;c(7,1,4) =       145478651._R_P/   1112277._R_P
    !                    /                               ;                     /
    c(8,1,4) =     -42281552._R_P/ 2841263._R_P

    !                    /                               ;                     /
    c(0,2,4) =                                     0._R_P;c(1,2,4) =                                     0._R_P
    !                    /                               ;                     /
    c(2,2,4) =     467443989._R_P/  432139._R_P;c(3,2,4) =   -1014379655._R_P/  237166._R_P
    !                    /                               ;                     /
    c(4,2,4) =      1427976276._R_P/    274865._R_P;c(5,2,4) =    -1288674710._R_P/   324261._R_P
    !                    /                               ;                     /
    c(6,2,4) =    56509897._R_P/  30173._R_P;c(7,2,4) =   -379006664._R_P/ 761061._R_P
    !                    /                               ;                     /
    c(8,2,4) =     179193514._R_P/3127239._R_P

    !                    /                               ;                     /
    c(0,3,4) =                                     0._R_P;c(1,3,4) =                                     0._R_P
    !                    /                               ;                     /
    c(2,3,4) =                                     0._R_P;c(3,3,4) =   1224163507._R_P/ 283894._R_P
    !                    /                               ;                     /
    c(4,3,4) =   -1890391470._R_P/  177121._R_P;c(5,3,4) =    2682354099._R_P/  322987._R_P
    !                    /                               ;                     /
    c(6,3,4) =    -1288674710._R_P/   324261._R_P;c(7,3,4) =    889068808._R_P/ 829823._R_P
    !                    /                               ;                     /
    c(8,3,4) =   -247486780._R_P/1982753._R_P

    !                    /                               ;                     /
    c(0,4,4) =                                     0._R_P;c(1,4,4) =                                     0._R_P
    !                    /                               ;                     /
    c(2,4,4) =                                     0._R_P;c(3,4,4) =                                     0._R_P
    !                    /                               ;                     /
    c(4,4,4) =     7446840373._R_P/   1106172._R_P;c(5,4,4) =   -1890391470._R_P/  177121._R_P
    !                    /                               ;                     /
    c(6,4,4) =      1427976276._R_P/    274865._R_P;c(7,4,4) =   -659953893._R_P/ 463955._R_P
    !                    /                               ;                     /
    c(8,4,4) =     323192477._R_P/ 1923068._R_P

    !                    /                               ;                     /
    c(0,5,4) =                                     0._R_P;c(1,5,4) =                                     0._R_P
    !                    /                               ;                     /
    c(2,5,4) =                                     0._R_P;c(3,5,4) =                                     0._R_P
    !                    /                               ;                     /
    c(4,5,4) =                                     0._R_P;c(5,5,4) =    1224163507._R_P/ 283894._R_P
    !                    /                               ;                     /
    c(6,5,4) =   -1014379655._R_P/  237166._R_P;c(7,5,4) =    1066785823._R_P/ 895146._R_P
    !                    /                               ;                     /
    c(8,5,4) =   -81991005._R_P/573014._R_P

    !                    /                               ;                     /
    c(0,6,4) =                                     0._R_P;c(1,6,4) =                                     0._R_P
    !                    /                               ;                     /
    c(2,6,4) =                                     0._R_P;c(3,6,4) =                                     0._R_P
    !                    /                               ;                     /
    c(4,6,4) =                                     0._R_P;c(5,6,4) =                                     0._R_P
    !                    /                               ;                     /
    c(6,6,4) =     467443989._R_P/  432139._R_P;c(7,6,4) =   -257255959._R_P/ 418532._R_P
    !                    /                               ;                     /
    c(8,6,4) =     48978927._R_P/ 651442._R_P

    !                    /                               ;                     /
    c(0,7,4) =                                     0._R_P;c(1,7,4) =                                     0._R_P
    !                    /                               ;                     /
    c(2,7,4) =                                     0._R_P;c(3,7,4) =                                     0._R_P
    !                    /                               ;                     /
    c(4,7,4) =                                     0._R_P;c(5,7,4) =                                     0._R_P
    !                    /                               ;                     /
    c(6,7,4) =                                     0._R_P;c(7,7,4) =    206821378._R_P/2319277._R_P
    !                    /                               ;                     /
    c(8,7,4) =     -471882251._R_P/ 21169910._R_P

    !                    /                               ;                     /
    c(0,8,4) =                                     0._R_P;c(1,8,4) =                                     0._R_P
    !                    /                               ;                     /
    c(2,8,4) =                                     0._R_P;c(3,8,4) =                                     0._R_P
    !                    /                               ;                     /
    c(4,8,4) =                                     0._R_P;c(5,8,4) =                                     0._R_P
    !                    /                               ;                     /
    c(6,8,4) =                                     0._R_P;c(7,8,4) =                                     0._R_P
    !                    /                               ;                     /
    c(8,8,4) =       25595175._R_P/ 17925332._R_P

    ! stencil 5
    !                    /                               ;                     /
    c(0,0,5) =       25595175._R_P/ 17925332._R_P;c(1,0,5) =     -28933143._R_P/ 1204235._R_P
    !                    /                               ;                     /
    c(2,0,5) =    67366110._R_P/766169._R_P;c(3,0,5) =    -185363617._R_P/ 1015232._R_P
    !                    /                               ;                     /
    c(4,0,5) =      85841095._R_P/  365273._R_P;c(5,0,5) =   -135160981._R_P/704829._R_P
    !                    /                               ;                     /
    c(6,0,5) =    83373698._R_P/861333._R_P;c(7,0,5) =    -243832589._R_P/8827552._R_P
    !                    /                               ;                     /
    c(8,0,5) =       33222819._R_P/ 9738314._R_P

    !                    /                               ;                     /
    c(0,1,5) =                                     0._R_P;c(1,1,5) =    193935861._R_P/1901234._R_P
    !                    /                               ;                     /
    c(2,1,5) =   -491966393._R_P/ 653081._R_P;c(3,1,5) =   855538459._R_P/ 542278._R_P
    !                    /                               ;                     /
    c(4,1,5) =   -6738238495._R_P/ 3291754._R_P;c(5,1,5) =   654146656._R_P/ 388723._R_P
    !                    /                               ;                     /
    c(6,1,5) =   -767075415._R_P/ 896921._R_P;c(7,1,5) =      544135101._R_P/   2215768._R_P
    !                    /                               ;                     /
    c(8,1,5) =    -417266048._R_P/13678797._R_P

    !                    /                               ;                     /
    c(0,2,5) =                                     0._R_P;c(1,2,5) =                                     0._R_P
    !                    /                               ;                     /
    c(2,2,5) =     2253530669._R_P/  1605103._R_P;c(3,2,5) =   -628691758._R_P/  105883._R_P
    !                    /                               ;                     /
    c(4,2,5) =      1581790037._R_P/    203396._R_P;c(5,2,5) =   -295058921._R_P/  45739._R_P
    !                    /                               ;                     /
    c(6,2,5) =    1033739711._R_P/  312683._R_P;c(7,2,5) =   -931274285._R_P/ 973468._R_P
    !                    /                               ;                     /
    c(8,2,5) =    184615935._R_P/1542601._R_P

    !                    /                               ;                     /
    c(0,3,5) =                                     0._R_P;c(1,3,5) =                                     0._R_P
    !                    /                               ;                     /
    c(2,3,5) =                                     0._R_P;c(3,3,5) =   4054421226._R_P/ 639143._R_P
    !                    /                               ;                     /
    c(4,3,5) =    -8099595796._R_P/   482187._R_P;c(5,3,5) =    3662929022._R_P/  260087._R_P
    !                    /                               ;                     /
    c(6,3,5) =   -828515195._R_P/  113623._R_P;c(7,3,5) =   1034492709._R_P/ 485618._R_P
    !                    /                               ;                     /
    c(8,3,5) =   -709458479._R_P/2638758._R_P

    !                    /                               ;                     /
    c(0,4,5) =                                     0._R_P;c(1,4,5) =                                     0._R_P
    !                    /                               ;                     /
    c(2,4,5) =                                     0._R_P;c(3,4,5) =                                     0._R_P
    !                    /                               ;                     /
    c(4,4,5) =     1548885060._R_P/   137633._R_P;c(5,4,5) =    -305554133._R_P/   15991._R_P
    !                    /                               ;                     /
    c(6,4,5) =      966000775._R_P/    96443._R_P;c(7,4,5) =   -787874261._R_P/ 266082._R_P
    !                    /                               ;                     /
    c(8,4,5) =     348597468._R_P/  922523._R_P

    !                    /                               ;                     /
    c(0,5,5) =                                     0._R_P;c(1,5,5) =                                     0._R_P
    !                    /                               ;                     /
    c(2,5,5) =                                     0._R_P;c(3,5,5) =                                     0._R_P
    !                    /                               ;                     /
    c(4,5,5) =                                     0._R_P;c(5,5,5) =   1879971092._R_P/ 228557._R_P
    !                    /                               ;                     /
    c(6,5,5) =   -3054791233._R_P/  349036._R_P;c(7,5,5) =   5590654438._R_P/ 2129495._R_P
    !                    /                               ;                     /
    c(8,5,5) =    -597649141._R_P/  1759029._R_P

    !                    /                               ;                     /
    c(0,6,5) =                                     0._R_P;c(1,6,5) =                                     0._R_P
    !                    /                               ;                     /
    c(2,6,5) =                                     0._R_P;c(3,6,5) =                                     0._R_P
    !                    /                               ;                     /
    c(4,6,5) =                                     0._R_P;c(5,6,5) =                                     0._R_P
    !                    /                               ;                     /
    c(6,6,5) =     2349998749._R_P/  992475._R_P;c(7,6,5) =   -522065981._R_P/ 360998._R_P
    !                    /                               ;                     /
    c(8,6,5) =    103779883._R_P/544689._R_P

    !                    /                               ;                     /
    c(0,7,5) =                                     0._R_P;c(1,7,5) =                                     0._R_P
    !                    /                               ;                     /
    c(2,7,5) =                                     0._R_P;c(3,7,5) =                                     0._R_P
    !                    /                               ;                     /
    c(4,7,5) =                                     0._R_P;c(5,7,5) =                                     0._R_P
    !                    /                               ;                     /
    c(6,7,5) =                                     0._R_P;c(7,7,5) =    308180301._R_P/1366333._R_P
    !                    /                               ;                     /
    c(8,7,5) =     -186193587._R_P/ 3061888._R_P

    !                    /                               ;                     /
    c(0,8,5) =                                     0._R_P;c(1,8,5) =                                     0._R_P
    !                    /                               ;                     /
    c(2,8,5) =                                     0._R_P;c(3,8,5) =                                     0._R_P
    !                    /                               ;                     /
    c(4,8,5) =                                     0._R_P;c(5,8,5) =                                     0._R_P
    !                    /                               ;                     /
    c(6,8,5) =                                     0._R_P;c(7,8,5) =                                     0._R_P
    !                    /                               ;                     /
    c(8,8,5) =       14225607._R_P/ 3370285._R_P

    ! stencil 6
    !                    /                               ;                     /
    c(0,0,6) =       14225607._R_P/ 3370285._R_P;c(1,0,6) =     -178701734._R_P/  2462661._R_P
    !                    /                               ;                     /
    c(2,0,6) =     329649921._R_P/ 1205744._R_P;c(3,0,6) =   -823497572._R_P/1397105._R_P
    !                    /                               ;                     /
    c(4,0,6) =    537364516._R_P/ 676097._R_P;c(5,0,6) =   -427576737._R_P/623480._R_P
    !                    /                               ;                     /
    c(6,0,6) =    383212815._R_P/1037536._R_P;c(7,0,6) =     -264553111._R_P/  2333462._R_P
    !                    /                               ;                     /
    c(8,0,6) =     265338548._R_P/17495633._R_P

    !                    /                               ;                     /
    c(0,1,6) =                                     0._R_P;c(1,1,6) =    267692197._R_P/856297._R_P
    !                    /                               ;                     /
    c(2,1,6) =   -1883344606._R_P/ 797417._R_P;c(3,1,6) =   982680142._R_P/ 192447._R_P
    !                    /                               ;                     /
    c(4,1,6) =   -2267814051._R_P/ 328385._R_P;c(5,1,6) =   1268411423._R_P/ 212206._R_P
    !                    /                               ;                     /
    c(6,1,6) =  -676787627._R_P/ 209575._R_P;c(7,1,6) =     127754174._R_P/   128481._R_P
    !                    /                               ;                     /
    c(8,1,6) =   -173397370._R_P/1299717._R_P

    !                    /                               ;                     /
    c(0,2,6) =                                     0._R_P;c(1,2,6) =                                     0._R_P
    !                    /                               ;                     /
    c(2,2,6) =     2952652193._R_P/  659941._R_P;c(3,2,6) =   -5961122741._R_P/  307109._R_P
    !                    /                               ;                     /
    c(4,2,6) =      451561861._R_P/    17139._R_P;c(5,2,6) =   -2468363819._R_P/   107827._R_P
    !                    /                               ;                     /
    c(6,2,6) =   2097415117._R_P/  168915._R_P;c(7,2,6) =  -2367490577._R_P/ 616772._R_P
    !                    /                               ;                     /
    c(8,2,6) =    688214053._R_P/1331147._R_P

    !                    /                               ;                     /
    c(0,3,6) =                                     0._R_P;c(1,3,6) =                                     0._R_P
    !                    /                               ;                     /
    c(2,3,6) =                                     0._R_P;c(3,3,6) =   3256858005._R_P/ 154108._R_P
    !                    /                               ;                     /
    c(4,3,6) =  -7546651472._R_P/  130969._R_P;c(5,3,6) =   3655479387._R_P/  72668._R_P
    !                    /                               ;                     /
    c(6,3,6) =  -765629878._R_P/  27919._R_P;c(7,3,6) =   5241495620._R_P/ 615127._R_P
    !                    /                               ;                     /
    c(8,3,6) =  -61463934._R_P/53285._R_P

    !                    /                               ;                     /
    c(0,4,6) =                                     0._R_P;c(1,4,6) =                                     0._R_P
    !                    /                               ;                     /
    c(2,4,6) =                                     0._R_P;c(3,4,6) =                                     0._R_P
    !                    /                               ;                     /
    c(4,4,6) =    11322353265._R_P/   286802._R_P;c(5,4,6) =  -4882065990._R_P/  70417._R_P
    !                    /                               ;                     /
    c(6,4,6) =      1334723167._R_P/    35090._R_P;c(7,4,6) =  -10107954583._R_P/ 849559._R_P
    !                    /                               ;                     /
    c(8,4,6) =    306856831._R_P/ 189251._R_P

    !                    /                               ;                     /
    c(0,5,6) =                                     0._R_P;c(1,5,6) =                                     0._R_P
    !                    /                               ;                     /
    c(2,5,6) =                                     0._R_P;c(3,5,6) =                                     0._R_P
    !                    /                               ;                     /
    c(4,5,6) =                                     0._R_P;c(5,5,6) =   2631362108._R_P/ 85845._R_P
    !                    /                               ;                     /
    c(6,5,6) =  -2028942806._R_P/  59843._R_P;c(7,5,6) =   2363787227._R_P/ 220958._R_P
    !                    /                               ;                     /
    c(8,5,6) =  -289784372._R_P/196989._R_P

    !                    /                               ;                     /
    c(0,6,6) =                                     0._R_P;c(1,6,6) =                                     0._R_P
    !                    /                               ;                     /
    c(2,6,6) =                                     0._R_P;c(3,6,6) =                                     0._R_P
    !                    /                               ;                     /
    c(4,6,6) =                                     0._R_P;c(5,6,6) =                                     0._R_P
    !                    /                               ;                     /
    c(6,6,6) =    3248190394._R_P/  343067._R_P;c(7,6,6) =  -1651888798._R_P/ 273307._R_P
    !                    /                               ;                     /
    c(8,6,6) =   277579576._R_P/329887._R_P

    !                    /                               ;                     /
    c(0,7,6) =                                     0._R_P;c(1,7,6) =                                     0._R_P
    !                    /                               ;                     /
    c(2,7,6) =                                     0._R_P;c(3,7,6) =                                     0._R_P
    !                    /                               ;                     /
    c(4,7,6) =                                     0._R_P;c(5,7,6) =                                     0._R_P
    !                    /                               ;                     /
    c(6,7,6) =                                     0._R_P;c(7,7,6) =   526012837._R_P/537300._R_P
    !                    /                               ;                     /
    c(8,7,6) =     -699447262._R_P/  2521667._R_P

    !                    /                               ;                     /
    c(0,8,6) =                                     0._R_P;c(1,8,6) =                                     0._R_P
    !                    /                               ;                     /
    c(2,8,6) =                                     0._R_P;c(3,8,6) =                                     0._R_P
    !                    /                               ;                     /
    c(4,8,6) =                                     0._R_P;c(5,8,6) =                                     0._R_P
    !                    /                               ;                     /
    c(6,8,6) =                                     0._R_P;c(7,8,6) =                                     0._R_P
    !                    /                               ;                     /
    c(8,8,6) =      36409563._R_P/ 1806520._R_P

    ! stencil 7
    !                    /                               ;                     /
    c(0,0,7) =      36409563._R_P/ 1806520._R_P;c(1,0,7) =    -296572045._R_P/ 853161._R_P
    !                    /                               ;                     /
    c(2,0,7) =   1414733955._R_P/1073627._R_P;c(3,0,7) =  -557744521._R_P/194407._R_P
    !                    /                               ;                     /
    c(4,0,7) =    1990119523._R_P/ 506979._R_P;c(5,0,7) =  -1275601375._R_P/368936._R_P
    !                    /                               ;                     /
    c(6,0,7) =   2064497172._R_P/1078127._R_P;c(7,0,7) =   -759205271._R_P/1245236._R_P
    !                    /                               ;                     /
    c(8,0,7) =    192493416._R_P/2253847._R_P

    !                    /                               ;                     /
    c(0,1,7) =                                     0._R_P;c(1,1,7) =    550334507._R_P/ 366830._R_P
    !                    /                               ;                     /
    c(2,1,7) =  -1486183058._R_P/ 130527._R_P;c(3,1,7) =   1696424402._R_P/ 68349._R_P
    !                    /                               ;                     /
    c(4,1,7) =  -5136703769._R_P/ 151046._R_P;c(5,1,7) =  2675355119._R_P/ 89174._R_P
    !                    /                               ;                     /
    c(6,1,7) =  -2519869819._R_P/ 151381._R_P;c(7,1,7) =     1632642660._R_P/   307433._R_P
    !                    /                               ;                     /
    c(8,1,7) =     -433682386._R_P/  581703._R_P

    !                    /                               ;                     /
    c(0,2,7) =                                     0._R_P;c(1,2,7) =                                     0._R_P
    !                    /                               ;                     /
    c(2,2,7) =    3171898228._R_P/  146643._R_P;c(3,2,7) =  -7652084383._R_P/  81028._R_P
    !                    /                               ;                     /
    c(4,2,7) =     4693138545._R_P/    36209._R_P;c(5,2,7) =  -5737609802._R_P/  50081._R_P
    !                    /                               ;                     /
    c(6,2,7) =   2904329890._R_P/  45589._R_P;c(7,2,7) =  -684405583._R_P/ 33590._R_P
    !                    /                               ;                     /
    c(8,2,7) =   1206026846._R_P/420471._R_P

    !                    /                               ;                     /
    c(0,3,7) =                                     0._R_P;c(1,3,7) =                                     0._R_P
    !                    /                               ;                     /
    c(2,3,7) =                                     0._R_P;c(3,3,7) =  10194856899._R_P/ 98734._R_P
    !                    /                               ;                     /
    c(4,3,7) =  -32956224478._R_P/  116041._R_P;c(5,3,7) =  21903079582._R_P/  87043._R_P
    !                    /                               ;                     /
    c(6,3,7) =  -30871077827._R_P/   220014._R_P;c(7,3,7) =  2631734550._R_P/ 58459._R_P
    !                    /                               ;                     /
    c(8,3,7) =  -1432715713._R_P/225284._R_P

    !                    /                               ;                     /
    c(0,4,7) =                                     0._R_P;c(1,4,7) =                                     0._R_P
    !                    /                               ;                     /
    c(2,4,7) =                                     0._R_P;c(3,4,7) =                                     0._R_P
    !                    /                               ;                     /
    c(4,4,7) =   5232843359._R_P/   26730._R_P;c(5,4,7) =  -21436202114._R_P/  61611._R_P
    !                    /                               ;                     /
    c(6,4,7) =     8450768743._R_P/    43407._R_P;c(7,4,7) =  -2463944763._R_P/ 39286._R_P
    !                    /                               ;                     /
    c(8,4,7) =   2318146475._R_P/ 260443._R_P

    !                    /                               ;                     /
    c(0,5,7) =                                     0._R_P;c(1,5,7) =                                     0._R_P
    !                    /                               ;                     /
    c(2,5,7) =                                     0._R_P;c(3,5,7) =                                     0._R_P
    !                    /                               ;                     /
    c(4,5,7) =                                     0._R_P;c(5,5,7) =  7222761881._R_P/ 46553._R_P
    !                    /                               ;                     /
    c(6,5,7) =  -12258216466._R_P/  70285._R_P;c(7,5,7) =  17759778441._R_P/ 314408._R_P
    !                    /                               ;                     /
    c(8,5,7) = -351689199._R_P/43600._R_P

    !                    /                               ;                     /
    c(0,6,7) =                                     0._R_P;c(1,6,7) =                                     0._R_P
    !                    /                               ;                     /
    c(2,6,7) =                                     0._R_P;c(3,6,7) =                                     0._R_P
    !                    /                               ;                     /
    c(4,6,7) =                                     0._R_P;c(5,6,7) =                                     0._R_P
    !                    /                               ;                     /
    c(6,6,7) =    138686396638._R_P/  2813507._R_P;c(7,6,7) = -6349489117._R_P/ 197436._R_P
    !                    /                               ;                     /
    c(8,6,7) =   1919279425._R_P/ 414313._R_P

    !                    /                               ;                     /
    c(0,7,7) =                                     0._R_P;c(1,7,7) =                                     0._R_P
    !                    /                               ;                     /
    c(2,7,7) =                                     0._R_P;c(3,7,7) =                                     0._R_P
    !                    /                               ;                     /
    c(4,7,7) =                                     0._R_P;c(5,7,7) =                                     0._R_P
    !                    /                               ;                     /
    c(6,7,7) =                                     0._R_P;c(7,7,7) =   8788336457._R_P/1659246._R_P
    !                    /                               ;                     /
    c(8,7,7) =   -1605498941._R_P/ 1038640._R_P

    !                    /                               ;                     /
    c(0,8,7) =                                     0._R_P;c(1,8,7) =                                     0._R_P
    !                    /                               ;                     /
    c(2,8,7) =                                     0._R_P;c(3,8,7) =                                     0._R_P
    !                    /                               ;                     /
    c(4,8,7) =                                     0._R_P;c(5,8,7) =                                     0._R_P
    !                    /                               ;                     /
    c(6,8,7) =                                     0._R_P;c(7,8,7) =                                     0._R_P
    !                    /                               ;                     /
    c(8,8,7) =     23000337._R_P/ 199768._R_P

    ! stencil 8
    !                    /                               ;                     /
    c(0,0,8) =     23000337._R_P/ 199768._R_P;c(1,0,8) =   -989259649._R_P/ 497859._R_P
    !                    /                               ;                     /
    c(2,0,8) =   2005851423._R_P/265880._R_P;c(3,0,8) =   -800361473._R_P/  48582._R_P
    !                    /                               ;                     /
    c(4,0,8) =   1211629703._R_P/  53483._R_P;c(5,0,8) = -16400242834._R_P/815393._R_P
    !                    /                               ;                     /
    c(6,0,8) =  2160095091._R_P/191558._R_P;c(7,0,8) =  -1039356853._R_P/284187._R_P
    !                    /                               ;                     /
    c(8,0,8) =    380112881._R_P/ 721737._R_P

    !                    /                               ;                     /
    c(0,1,8) =                                     0._R_P;c(1,1,8) =  1207396129._R_P/140764._R_P
    !                    /                               ;                     /
    c(2,1,8) = -5910597075._R_P/ 90694._R_P;c(3,1,8) =  6203677189._R_P/ 43561._R_P
    !                    /                               ;                     /
    c(4,1,8) = -29831101642._R_P/ 152201._R_P;c(5,1,8) = 8534140303._R_P/ 48995._R_P
    !                    /                               ;                     /
    c(6,1,8) = -7469836609._R_P/ 76401._R_P;c(7,1,8) =    962141663._R_P/   30298._R_P
    !                    /                               ;                     /
    c(8,1,8) =  -1382011106._R_P/301683._R_P

    !                    /                               ;                     /
    c(0,2,8) =                                     0._R_P;c(1,2,8) =                                     0._R_P
    !                    /                               ;                     /
    c(2,2,8) =   9873545067._R_P/  79705._R_P;c(3,2,8) = -10120501295._R_P/  18678._R_P
    !                    /                               ;                     /
    c(4,2,8) =    9817971019._R_P/    13153._R_P;c(5,2,8) = -13534679320._R_P/  20379._R_P
    !                    /                               ;                     /
    c(6,2,8) =  8640690184._R_P/  23145._R_P;c(7,2,8) = -7097325924._R_P/ 58429._R_P
    !                    /                               ;                     /
    c(8,2,8) =  7116193241._R_P/405236._R_P

    !                    /                               ;                     /
    c(0,3,8) =                                     0._R_P;c(1,3,8) =                                     0._R_P
    !                    /                               ;                     /
    c(2,3,8) =                                     0._R_P;c(3,3,8) = 181942554161._R_P/ 306771._R_P
    !                    /                               ;                     /
    c(4,3,8) =  -32852743324._R_P/   20081._R_P;c(5,3,8) =  25425670807._R_P/  17442._R_P
    !                    /                               ;                     /
    c(6,3,8) = -13491549889._R_P/  16436._R_P;c(7,3,8) = 13666821827._R_P/ 51060._R_P
    !                    /                               ;                     /
    c(8,3,8) = -12858081715._R_P/331389._R_P

    !                    /                               ;                     /
    c(0,4,8) =                                     0._R_P;c(1,4,8) =                                     0._R_P
    !                    /                               ;                     /
    c(2,4,8) =                                     0._R_P;c(3,4,8) =                                     0._R_P
    !                    /                               ;                     /
    c(4,4,8) =   7211727349._R_P/   6383._R_P;c(5,4,8) =  -34046474687._R_P/   16880._R_P
    !                    /                               ;                     /
    c(6,4,8) =    29334155111._R_P/    25771._R_P;c(7,4,8) = -14121568547._R_P/ 37942._R_P
    !                    /                               ;                     /
    c(8,4,8) =    8028408627._R_P/  148285._R_P

    !                    /                               ;                     /
    c(0,5,8) =                                     0._R_P;c(1,5,8) =                                     0._R_P
    !                    /                               ;                     /
    c(2,5,8) =                                     0._R_P;c(3,5,8) =                                     0._R_P
    !                    /                               ;                     /
    c(4,5,8) =                                     0._R_P;c(5,5,8) = 26479157148._R_P/ 29351._R_P
    !                    /                               ;                     /
    c(6,5,8) = -32612776236._R_P/  31939._R_P;c(7,5,8) = 10624327325._R_P/ 31707._R_P
    !                    /                               ;                     /
    c(8,5,8) = -6519672839._R_P/ 133134._R_P

    !                    /                               ;                     /
    c(0,6,8) =                                     0._R_P;c(1,6,8) =                                     0._R_P
    !                    /                               ;                     /
    c(2,6,8) =                                     0._R_P;c(3,6,8) =                                     0._R_P
    !                    /                               ;                     /
    c(4,6,8) =                                     0._R_P;c(5,6,8) =                                     0._R_P
    !                    /                               ;                     /
    c(6,6,8) =   958711850795._R_P/  3306139._R_P;c(7,6,8) = -2523726139._R_P/ 13197._R_P
    !                    /                               ;                     /
    c(8,6,8) =  1051885279._R_P/37394._R_P

    !                    /                               ;                     /
    c(0,7,8) =                                     0._R_P;c(1,7,8) =                                     0._R_P
    !                    /                               ;                     /
    c(2,7,8) =                                     0._R_P;c(3,7,8) =                                     0._R_P
    !                    /                               ;                     /
    c(4,7,8) =                                     0._R_P;c(5,7,8) =                                     0._R_P
    !                    /                               ;                     /
    c(6,7,8) =                                     0._R_P;c(7,7,8) =   2789709824._R_P/ 87891._R_P
    !                    /                               ;                     /
    c(8,7,8) =   -1291706883._R_P/ 137012._R_P

    !                    /                               ;                     /
    c(0,8,8) =                                     0._R_P;c(1,8,8) =                                     0._R_P
    !                    /                               ;                     /
    c(2,8,8) =                                     0._R_P;c(3,8,8) =                                     0._R_P
    !                    /                               ;                     /
    c(4,8,8) =                                     0._R_P;c(5,8,8) =                                     0._R_P
    !                    /                               ;                     /
    c(6,8,8) =                                     0._R_P;c(7,8,8) =                                     0._R_P
    !                    /                               ;                     /
    c(8,8,8) =    191906863._R_P/ 270061._R_P
  endselect
  end subroutine assign_beta_coeff
endmodule wenoof_beta_int_js
