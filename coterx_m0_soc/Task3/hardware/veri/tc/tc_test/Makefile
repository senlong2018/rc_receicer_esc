host=`who am i |cut -d " " -f 1`
case=`pwd | sed "s/^.*\///"`

cover=-cm line +cond+fsm+tgl+branch -cm_dir ../coverage/vdb/$(case)

inc_path=+incdir+../../code/include \
				 +incdir+../../../veri/tb
verdi_cmp=vericom -work work $(inc_path)

target=tc_test

help:
	@echo "==================================help============================" 
	@echo "1.make sim            --function sim used vcs                     "
	@echo "2.make psim-min       --post sim with min sdf                     "
	@echo "3.make psim-max       --post sim with max sdf                     "
	@echo "4.make sim-wave       --function sim used vcs and dve             "
	@echo "5.make psim-min-wave  --post sim with min sdf and generate wave   "
	@echo "6.make psim-max-wave  --post sim with max sdf and generate wave   "
	@echo "7.make sim-verdi      --sim use vcs and verdi                     "
	@echo "8.make verdi          --use verdi to debug                        "
	@echo "9.make nc-wave        --function sim used nc-verilog              "
	@echo "10.make clean         --clean unused files                        "
	@echo "=================================================================="

gen-wave:
	@if ! [ -e ./sim_wave ]; then \
		mkdir sim_wave; \
	fi

sim-wave: gen-wave
	vcs \
	-R -I +v2k \
	+incdir+ ../../../veri/tb \
	+incdir+ ../../../code/include \
	-sverilog \
	-f ../../tb/filelist \
	-f ../../tb/codelist \
	$(target).v \
	-l sim.log \
  +define+SIM+VCS_SIM \
  +define+VPD \
  +vpdfile+sim_wave/sim.vpd \
	-v /ven/tsmc/tmsc018_BCD_GEN3_digital/M31LLSC1050TH180GS_00.02.000/M31LLSC1050TH180GS.0.02/verilog/M31LLSC1050TH180GS.v \
	-v /ven/tsmc/tmsc018_BCD_GEN3_digital/M31GPIO1850TH180G_00.02.000/M31GPIO1850TH180G.0.02/verilog/M31GPIO1850TH180G.v \
	-v ../../tb/tef018_efuse_32.v \
	-v ../../tb/tef018_efuse_64.v \
  +typelays \
	+access+wr

sim-verdi:
	vcs  \
	-kdb \
	+notimingcheck \
	+nospecify \
	-full64 \
	-debug_access+all \
	-sverilog \
	+incdir+../../tb \
	-f ../../tb/filelist \
	-f ../../tb/codelist \
	-override_timescale=1ns/1ps \
	$(target).v \
	-l sim.log \
	+fsdbfile+$(target).fsdb \
	+fsdb+all \
	-R

# verdi:
# 	verdi \
# 	-nologo \
# 	-sv \
# 	$(target).v \
# 	-f ../../tb/filelist \
# 	-f ../../tb/codelist \
# 	-ssf $(target).fsdb & 

verdi:
	verdi \
	-ssf $(target).fsdb \
	-elab 	simv.daidir/kdb.elab++ &

psim-min:
	vcs \
  -R -I +v2k \
	+incdir+ ../../../veri/tb \
	+incdir+ ../../../code/include \
	+preload_file=./preload.data \
	-sverilog \
	-f ../../tb/filelist \
	-f ../../tb/codelist_psim \
	-v /ven/tsmc/tmsc018_BCD_GEN3_digital/M31LLSC1050TH180GS_00.02.000/M31LLSC1050TH180GS.0.02/verilog/M31LLSC1050TH180GS.v \
	-v /ven/tsmc/tmsc018_BCD_GEN3_digital/M31GPIO1850TH180G_00.02.000/M31GPIO1850TH180G.0.02/verilog/M31GPIO1850TH180G.v \
	-v ../../tb/tef018_efuse_32.v \
	-v ../../tb/tef018_efuse_64.v \
	$(target).v \
	-l psim_min.log \
	+define SIM+PSIM+PSIM_MIN+VCS+SIM \
	+typdelays \
	+optconfigfile+async.list \
 +access+wr

psim-min-wave: gen-wave
	vcs \
  -R -I +v2k \
	+incdir+ ../../../veri/tb \
	+incdir+ ../../../code/include \
	+preload_file=./preload.data \
	-sverilog \
	-f ../../tb/filelist \
	-f ../../tb/codelist_psim \
  +define+VPD \
  +vpdfile+sim_wave/$()_psim_min.vpd \
	-v /ven/tsmc/tmsc018_BCD_GEN3_digital/M31LLSC1050TH180GS_00.02.000/M31LLSC1050TH180GS.0.02/verilog/M31LLSC1050TH180GS.v \
	-v /ven/tsmc/tmsc018_BCD_GEN3_digital/M31GPIO1850TH180G_00.02.000/M31GPIO1850TH180G.0.02/verilog/M31GPIO1850TH180G.v \
	-v ../../tb/tef018_efuse_32.v \
	-v ../../tb/tef018_efuse_64.v \
	$(target).v \
	-l psim_min.log \
	+define SIM+PSIM+PSIM_MIN+VCS+SIM \
	+typdelays \
	+optconfigfile+async.list \
 +access+wr

psim-max:
	vcs \
  -R -I +v2k \
	+incdir+ ../../../veri/tb \
	+incdir+ ../../../code/include \
	+preload_file=./preload.data \
	-sverilog \
	-f ../../tb/filelist \
	-f ../../tb/codelist_psim \
	-v /ven/tsmc/tmsc018_BCD_GEN3_digital/M31LLSC1050TH180GS_00.02.000/M31LLSC1050TH180GS.0.02/verilog/M31LLSC1050TH180GS.v \
	-v /ven/tsmc/tmsc018_BCD_GEN3_digital/M31GPIO1850TH180G_00.02.000/M31GPIO1850TH180G.0.02/verilog/M31GPIO1850TH180G.v \
	-v ../../tb/tef018_efuse_32.v \
	-v ../../tb/tef018_efuse_64.v \
	$(target).v \
	-l psim_min.log \
	+define SIM+PSIM+PSIM_MAX+VCS+SIM \
	+typdelays \
	+optconfigfile+async.list \
 +access+wr

psim-max-wave: gen-wave
	vcs \
  -R -I +v2k \
	+incdir+ ../../../veri/tb \
	+incdir+ ../../../code/include \
	+preload_file=./preload.data \
	-sverilog \
	-f ../../tb/filelist \
	-f ../../tb/codelist_psim \
  +define+VPD \
  +vpdfile+sim_wave/$()_psim_max.vpd \
	-v /ven/tsmc/tmsc018_BCD_GEN3_digital/M31LLSC1050TH180GS_00.02.000/M31LLSC1050TH180GS.0.02/verilog/M31LLSC1050TH180GS.v \
	-v /ven/tsmc/tmsc018_BCD_GEN3_digital/M31GPIO1850TH180G_00.02.000/M31GPIO1850TH180G.0.02/verilog/M31GPIO1850TH180G.v \
	-v ../../tb/tef018_efuse_32.v \
	-v ../../tb/tef018_efuse_64.v \
	$(target).v \
	-l psim_min.log \
	+define SIM+PSIM+PSIM_MAX+VCS+SIM \
	+typdelays \
	+optconfigfile+async.list \
 +access+wr

dve:
	dve -vpd ./sim_wave/sim.vpd &

clean:
	rm -rf DVEfiles \
	*.bak \
	*.log \
	simv* \
	*.key \
	csrc \
	verdiLog \
	*.conf \
	simv