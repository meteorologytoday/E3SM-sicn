
module ice_prescribed_mod

   use mpas_framework
   use mpas_log, only: mpas_log_write
   use mpas_derived_types
   use mpas_pool_routines
   use mpas_timer


  implicit none
  public :: ice_prescribed_run, ice_prescribed_init, seaice_run_prescribed_ice
  
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


!|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
!
!  seaice_run_prescribed_ice
!
!> \brief
!> \author Adrian K. Turner, LANL
!> \date 7th November 2018
!> \details
!>
!
!-----------------------------------------------------------------------

  subroutine seaice_run_prescribed_ice(domain)

    use seaice_constants, only: &
         seaicePuny

    use ice_colpkg, only: &
         colpkg_enthalpy_snow, &
         colpkg_enthalpy_ice, &
         colpkg_salinity_profile

    use seaice_column, only: &
         seaice_column_reinitialize_fluxes, &
         seaice_column_aggregate

    type (domain_type), intent(inout) :: &
         domain !< Input/Output:

    type(block_type), pointer :: &
         blockPtr

    type(mpas_pool_type), pointer :: &
         prescribedIcePool, &
         tracersPool, &
         initialPool, &
         oceanCouplingPool, &
         meshPool, &
         velocitySolverPool

    real(kind=RKIND), dimension(:), pointer :: &
         iceCoverage, &
         categoryThicknessLimits, &
         seaFreezingTemperature, &
         latCell, &
         freezingMeltingPotential, &
         uVelocity, &
         vVelocity, &
         oceanStressCellU, &
         oceanStressCellV

    real(kind=RKIND), dimension(:,:,:), pointer :: &
         iceAreaCategory, &
         iceVolumeCategory, &
         snowVolumeCategory, &
         surfaceTemperature, &
         iceEnthalpy, &
         iceSalinity, &
         snowEnthalpy

    real(kind=RKIND) :: &
         iceThickness, &
         snowThickness, &
         depth, &
         iceTemperature, &
         temperatureGradient

    real(kind=RKIND), pointer :: &
         config_dt

    integer, pointer :: &
         nCells, &
         nCategories, &
         nIceLayers, &
         nSnowLayers

    integer :: &
         iCell, &
         iCategory, &
         iIceLayer, &
         iSnowLayer


        print *, "Entering prescribe seaice mode"

       blockPtr => domain % blocklist
       do while (associated(blockPtr))
        
            print *, "Entering a block"
            print *, "Getting pools"

          !call mpas_pool_get_subpool(blockPtr % structs, "prescribed_ice", prescribedIcePool)
          call mpas_pool_get_subpool(blockPtr % structs, "tracers", tracersPool)
          call mpas_pool_get_subpool(blockPtr % structs, "initial", initialPool)
          call mpas_pool_get_subpool(blockPtr % structs, "ocean_coupling", oceanCouplingPool)
          call mpas_pool_get_subpool(blockPtr % structs, "mesh", meshPool)

          !call mpas_pool_get_array(prescribedIcePool, "iceCoverage", iceCoverage)

          call mpas_pool_get_array(tracersPool, "iceAreaCategory", iceAreaCategory, 1)
          call mpas_pool_get_array(tracersPool, "iceVolumeCategory", iceVolumeCategory, 1)
          call mpas_pool_get_array(tracersPool, "snowVolumeCategory", snowVolumeCategory, 1)
          call mpas_pool_get_array(tracersPool, "surfaceTemperature", surfaceTemperature, 1)
          call mpas_pool_get_array(tracersPool, "iceEnthalpy", iceEnthalpy, 1)
          call mpas_pool_get_array(tracersPool, "iceSalinity", iceSalinity, 1)
          call mpas_pool_get_array(tracersPool, "snowEnthalpy", snowEnthalpy, 1)

          call mpas_pool_get_array(initialPool, "categoryThicknessLimits", categoryThicknessLimits)

          call mpas_pool_get_array(oceanCouplingPool, "seaFreezingTemperature", seaFreezingTemperature)

          call mpas_pool_get_array(meshPool, "latCell", latCell)

          call mpas_pool_get_dimension(blockPtr % dimensions, "nCells", nCells)
          call mpas_pool_get_dimension(blockPtr % dimensions, "nCategories", nCategories)
          call mpas_pool_get_dimension(blockPtr % dimensions, "nIceLayers", nIceLayers)
          call mpas_pool_get_dimension(blockPtr % dimensions, "nSnowLayers", nSnowLayers)

          print *, "Prescribing ice thickness"
          do iCell = 1, nCells

             ! limit ice coverage
             !if (iceCoverage(iCell) < 1e-4_RKIND) iceCoverage(iCell) = 0.0_RKIND
             !if (iceCoverage(iCell) > 1.0_RKIND)  iceCoverage(iCell) = 1.0_RKIND

             if ( latCell(iCell) >= (40.0 *3.14159/180.0) ) then

                ! set thickness based on hemisphere
                if (latCell(iCell) >= 0.0) then
                   iceThickness = 2.0_RKIND
                else if (latCell(iCell) < 0.0) then
                   iceThickness = 1.0_RKIND
                endif

                ! loop over categories
                do iCategory = 1, nCategories

                   ! find relevant thickness category
                   if (iceThickness >= categoryThicknessLimits(iCategory) .and. & !!!! index limits
                       iceThickness <  categoryThicknessLimits(iCategory+1)) then

                      if (iceAreaCategory(1,iCategory,iCell) > 0.0_RKIND) then
                         snowThickness = snowVolumeCategory(1,iCategory,iCell) / iceAreaCategory(1,iCategory,iCell)
                      else
                         snowThickness = 0.0_RKIND
                      endif ! prognostic ice present

                      ! reset ice state
                      iceAreaCategory(1,iCategory,iCell)    = 1.0_RKIND ! iceCoverage(iCell)
                      iceVolumeCategory(1,iCategory,iCell)  = iceThickness  * iceAreaCategory(1,iCategory,iCell)
                      snowVolumeCategory(1,iCategory,iCell) = snowThickness * iceAreaCategory(1,iCategory,iCell)

                      ! set thermodynamic tracers
                      if (abs(iceEnthalpy(1,iCategory,iCell)) < seaicePuny) then !!!!! check indices

                         if (iceAreaCategory(1,iCategory,iCell) < seaicePuny) then
                            surfaceTemperature(1,iCategory,iCell) = seaFreezingTemperature(iCell)
                         endif

                         temperatureGradient = seaFreezingTemperature(iCell) - surfaceTemperature(1,iCategory,iCell)

                         ! ice quantities
                         do iIceLayer = 1, nIceLayers

                            depth = (real(iIceLayer,kind=RKIND) - 0.5_RKIND) / real(nIceLayers,kind=RKIND)
                            iceTemperature = surfaceTemperature(1,iCategory,iCell) + temperatureGradient * depth
                            iceSalinity(iIceLayer,iCategory,iCell) = colpkg_salinity_profile(depth)
                            iceEnthalpy(iIceLayer,iCategory,iCell) = colpkg_enthalpy_ice(iceTemperature,iceSalinity(iIceLayer,iCategory,iCell))

                         enddo ! iIceLayer

                         ! snow quantities
                         do iSnowLayer = 1, nSnowLayers
                            snowEnthalpy(iSnowLayer,iCategory,iCell) = colpkg_enthalpy_snow(surfaceTemperature(1,iCategory,iCell))
                         enddo ! iSnowLayer

                      endif

                   else

                      surfaceTemperature(1,iCategory,iCell) = seaFreezingTemperature(iCell)
                      iceAreaCategory(1,iCategory,iCell)    = 0.0_RKIND
                      iceVolumeCategory(1,iCategory,iCell)  = 0.0_RKIND
                      snowVolumeCategory(1,iCategory,iCell) = 0.0_RKIND
                      iceSalinity(:,iCategory,iCell)        = 0.0_RKIND
                      iceEnthalpy(:,iCategory,iCell)        = 0.0_RKIND
                      snowEnthalpy(:,iCategory,iCell)       = 0.0_RKIND

                   endif ! in category

                enddo ! iCategory

             else

                ! low ice coverage
                surfaceTemperature(1,:,iCell) = seaFreezingTemperature(iCell)
                iceAreaCategory(1,:,iCell)    = 0.0_RKIND
                iceVolumeCategory(1,:,iCell)  = 0.0_RKIND
                snowVolumeCategory(1,:,iCell) = 0.0_RKIND
                iceSalinity(:,:,iCell)        = 0.0_RKIND
                iceEnthalpy(:,:,iCell)        = 0.0_RKIND
                snowEnthalpy(:,:,iCell)       = 0.0_RKIND

             endif ! ice coverage

          enddo ! iCell

          blockPtr => blockPtr % next
       enddo

        print *, "Aggregate tracers"
       ! aggregate tracers
       call seaice_column_aggregate(domain)

        print *, "Set non-computed fluxes."
       ! set non-computed fluxes, ice velocities, ice-ocn stresses to zero
       blockPtr => domain % blocklist
       do while (associated(blockPtr))

          call mpas_pool_get_subpool(blockPtr % structs, "velocity_solver", velocitySolverPool)
          call mpas_pool_get_subpool(blockPtr % structs, "ocean_coupling", oceanCouplingPool)

          call mpas_pool_get_array(oceanCouplingPool, "freezingMeltingPotential", freezingMeltingPotential)
          call mpas_pool_get_array(velocitySolverPool, "uVelocity", uVelocity)
          call mpas_pool_get_array(velocitySolverPool, "vVelocity", vVelocity)
          call mpas_pool_get_array(velocitySolverPool, "oceanStressCellU", oceanStressCellU)
          call mpas_pool_get_array(velocitySolverPool, "oceanStressCellV", oceanStressCellV)

          freezingMeltingPotential(:) = 0.0_RKIND
          uVelocity(:) = 0.0_RKIND
          vVelocity(:) = 0.0_RKIND
          oceanStressCellU(:) = 0.0_RKIND
          oceanStressCellV(:) = 0.0_RKIND

          blockPtr => blockPtr % next
       enddo

        print *, "Reinitialize fluxes"
       ! reinitialize fluxes
       call seaice_column_reinitialize_fluxes(domain)

  end subroutine seaice_run_prescribed_ice




 
! ===== [ Tien-Yiao modified end ] ====


end module ice_prescribed_mod

!|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
