
module ice_prescribed_mod

   use mpas_framework
   use mpas_log, only: mpas_log_write
   use mpas_derived_types
   use mpas_pool_routines
   use mpas_timer


  implicit none
  public :: ice_prescribed_run, ice_prescribed_init
  
  SAVE
  private                              ! By default make data private

    real(kind=RKIND) :: rad2deg = 180.0 / 3.1415926 
!=======================================================================

contains

! ===== [ Tien-Yiao modified begin ] ====

!***********************************************************************
!BOP
!
! !IROUTINE: ice_prescribed_init
!
! !INTERFACE:
  subroutine ice_prescribed_init()!{{{
!
! !DESCRIPTION:
! Initialize prescribed ice
!
! !USES:


       call MPAS_log_write(' ')
       call MPAS_log_write('Init ice prescribed module.')
       call MPAS_log_write(' ')

    
  end subroutine ice_prescribed_init

!***********************************************************************
!BOP
!
! !IROUTINE: ice_prescribed_run
!
! !INTERFACE
  subroutine ice_prescribed_run( domain, currTime )!{{{
!
! !DESCRIPTION:
! Set ice coverage for prescribed ice mode
!

! !INPUT/OUTPUT PARAMETERS:
    type (domain_type), pointer :: &
         domain
    type (MPAS_Time_Type), intent(in) :: &
         currTime
!-----------------------------------------------------------------------
!
!  local variables
!
!-----------------------------------------------------------------------


    logical, pointer :: &
         config_use_prescribed_ice

    integer :: &
         mDateIn, &
         secIn, &
         YYYY, MM, DD, DoY, H, M, S, &
         ierr

    integer :: &
         n, &
         iCell

    type (block_type), pointer :: &
         block_ptr

    type (mpas_pool_type), pointer :: &
         meshPool, &
         prescribedIcePool

    integer, pointer :: &
         nCellsSolve

    real(kind=RKIND), dimension(:), pointer :: &
         iceCoverage, &
         latCell

    type (field1DReal), pointer :: &
         iceCoverageField
 
    
    call MPAS_pool_get_config(domain % configs, "config_use_prescribed_ice", config_use_prescribed_ice)
    if (config_use_prescribed_ice) then

       call MPAS_get_time(currTime, YYYY, MM, DD, DoY, H, M, S, ierr)
       mDateIn = YYYY * 10000 + MM * 100 + DD
       secIn = H * 3600 + M * 60 + S

       n = 0
       block_ptr => domain % blocklist
       do while(associated(block_ptr))

          call MPAS_pool_get_subpool(block_ptr % structs, 'mesh', meshPool)
          call MPAS_pool_get_subpool(block_ptr % structs, 'prescribed_ice', prescribedIcePool)

          call MPAS_pool_get_dimension(meshPool, 'nCellsSolve', nCellsSolve)
          
          call MPAS_pool_get_array(meshPool, 'latCell', latCell)
          call MPAS_pool_get_array(prescribedIcePool, 'iceCoverage', iceCoverage)

          iceCoverage(:) = 0.0_RKIND

          do iCell = 1, nCellsSolve
             n = n + 1

             if (abs(latCell(iCell)) * rad2deg .ge. 40.0) then
                 iceCoverage(iCell) = 1.0
             endif
          enddo ! iCell

          block_ptr => block_ptr % next
       end do

       call MPAS_pool_get_subpool(domain % blocklist % structs, 'prescribed_ice', prescribedIcePool)
       call MPAS_pool_get_field(prescribedIcePool, 'iceCoverage', iceCoverageField)
       call MPAS_dmpar_exch_halo_field(iceCoverageField)

    endif

  end subroutine ice_prescribed_run

! ===== [ Tien-Yiao modified end ] ====


end module ice_prescribed_mod

!|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
