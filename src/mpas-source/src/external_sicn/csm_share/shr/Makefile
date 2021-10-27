.SUFFIXES: .F90 .o

OBJS := shr_strdata_mod.o shr_const_mod.o shr_kind_mod.o \
        shr_log_mod.o shr_sys_mod.o shr_file_mod.o shr_stream_mod.o \
        shr_map_mod.o shr_string_mod.o shr_cal_mod.o shr_orb_mod.o \
        shr_tinterp_mod.o shr_dmodel_mod.o shr_mct_mod.o mct_mod.o \
        perf_mod.o pio.o shr_mpi_mod.o seq_flds_mod.o shr_ncread_mod.o \
        shr_scam_mod.o shr_pcdf_mod.o shr_mct_mod.o mct_mod.o shr_timer_mod.o \
        seq_drydep_mod.o

all: $(OBJS)
	ar -ru libcsm_share.a *.o

clean:
	rm -rf *.tmp.f90 *.o *.mod *.a

.F90.o:
	$(RM) $@ $*.mod
ifeq "$(GEN_F90)" "true"
	$(CPP) $(CPPFLAGS) $< > $*.tmp.f90 $(CPPINCLUDES) $(FCINCLUDES) -I.
	$(FC) $(FFLAGS) -c $*.tmp.f90 $(CPPINCLUDES) $(FCINCLUDES) -I.
else
	$(FC) $(CPPFLAGS) $(FFLAGS) -c $*.F90 $(CPPINCLUDES) $(FCINCLUDES) -I.
endif
