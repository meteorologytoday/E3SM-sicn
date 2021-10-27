.SUFFIXES: .F .c .o

all: csm_share

csm_share:
	( cd csm_share/shr; $(MAKE) FC="$(FC) $(FFLAGS)" CPP="$(CPP)" CPPFLAGS="$(CPPFLAGS) -DHIDE_MPI" GEN_F90=$(GEN_F90) )

clean:
	( cd csm_share/shr; $(MAKE) clean )
