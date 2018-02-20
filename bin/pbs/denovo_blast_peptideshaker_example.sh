#PBS -P CBBI0825
#PBS -M matthys.potgieter@gmail.com
#PBS -l select=10:ncpus=24:nodetype=haswell_reg
#PBS -l walltime=48:00:00
#PBS -N UniversalPS
#PBS -q normal
#PBS -m be

# Config
experiment='S507_S5527_proteogenomics'
output_folder="/mnt/lustre/users/mpotgieter1/hh_out/hh"
spectrum_files="/home/mpotgieter1/lustre/blackburn/hypohyper/S507_S5527_hexdata/mgf_hh"
target_fasta="/mnt/lustre/users/mpotgieter1/blackburn/hypohyper/S507_S5527_hexdata/HYPOHYPER/proteomes/UP000001584_14_03_2016.fasta"
contaminant_fasta="/mnt/lustre/users/mpotgieter1/blackburn/hypohyper/S507_S5527_hexdata/HYPOHYPER/proteomes/gpm_crap_2016_07_03.fasta"
ps_folder='/home/mpotgieter1/software/PeptideShaker/PeptideShaker-1.13.1'
sg_folder='/home/mpotgieter1/software/SearchGUI/SearchGUI-3.1.0'

# SearchGUI parameters 
output_data='1'
xtandem='1'
myrimatch='1' 
ms_amanda='0'
msgf='1'
omssa='1'
comet='1'
tide='1'
andromeda='0'   # not on linux!

# Spectrum matching parameters
prec_tol=10
prec_ppm=1
frag_tol=0.02
frag_ppm=0
enzyme="Trypsin"
fixed_mods="Carbamidomethylation of C"
variable_mods="Oxidation of M, Acetylation of protein N-term"
min_charge=2
max_charge=4
mc=2
fi='b'
ri='y'

# Optional advanced parameters
mgf_splitting='1000'

# Spectrum annotation
annotation_level=0.75

# Import filters
import_peptide_length_min=7
import_peptide_length_max=30
psm_fdr=5
peptide_fdr=5
protein_fdr=5

# MyriMatch advanced parameters
myrimatch_min_pep_length=7
myrimatch_max_pep_length=30
# MS-GF advanced parameters
msgf_instrument=3
msgf_min_pep_length=7
msgf_max_pep_length=30

# OMSSA advanced parameters
tide_min_pep_length=7
tide_max_pep_length=30

# MzidCLI parameters #

contact_first_name='Nyari'
contact_last_name='Chigorimbo'
contact_email='Nyari.chigorimbo@hiv-research.org.za'
contact_address='Same as organization adress'
organization_name='University of Cape Town'
organization_email='organization@email.com'
organization_address='Anzio Road, Observatory'
contact_url='http://www.cbio.uct.ac.za/'
organization_url='http://www.cbio.uct.ac.za'

threads=24
psm_type=0
recalibrate=1  # recalibrate mgf funcionality of PeptideShaker (two searches will be done)
MSnID_FDR_value=1 #FDR to control global identifications (%)
MSnID_FDR_level="peptide"  # options are 'PSM','peptide','accession'

# gnu paralllel
ps_gnu_parallel_j=1

# Derivative jobs
headnode_user_ip=nchigorimbo@scp.chpc.ac.za  #headnode user account - NB for derivative qsub jobs
d_q='smp'
d_l='select=1:ncpus=24:mpiprocs=24'
d_P='CBBI0825'


############
# Pipeline #
############

set -e

JVM_ARGS="-d64 -Xms1024M -Xmx15360M -server"

source compomics.sh

if [ ! -d ${output_folder} ] ; then
    mkdir ${output_folder}
fi

mgf_file_count=$( find "${spectrum_files}" -name "*.mgf" | wc -l  )
# Check that config does not exist or is unchanged
if [ ! -f $output_folder/pipeline.pbs ] ; then
    cp "$(readlink -f $0)" $output_folder/pipeline.pbs
else
    cmp --silent "$(readlink -f $0)" $output_folder/pipeline.pbs && echo "'$(readlink -f $0)' unc    hanged."|| { echo "'$(readlink -f $0)' has changed, please delete '$output_folder' or replace '$(    readlink -f $0)' with the contents of pipeline.sh in "${output_folder}; exit 1; }
fi

if [ ! -d $output_folder/mgf ] ; then
    ps_prepare
fi

cd ${PBS_O_WORKDIR}
module add chpc/gnu/parallel-20160422

mgf_count=$( find "${output_folder}/mgf" -name "*.mgf" | wc -l  )
source `which env_parallel.bash`

if [ "${mgf_count}" -ne "0" ] ; then
    ls ${output_folder}/mgf/*.mgf | env_parallel --timeout 200% -j $ps_gnu_parallel_j -u --sshloginfile ${PBS_NODEFILE} "cd ${PBS_O_WORKDIR}; search $output_folder {}"
fi
wait

mzid_count=$( find "${output_folder}/mzIdentMLs" -name "*.mzid" | wc -l  )
if [ "${mzid_count}" -ne "${mgf_file_count}" ]; then
       echo 'There are unprocessed mgf files'
       exit 1
fi

if [ ! -d $output_folder/mzIdentMLS/analysis ]; then
   cmd="cd ${output_folder} && MSnIDshake.R -i mzIdentMLs/ -v ${MSnID_FDR_value} -l ${MSnID_FDR_level} && cd mzIdentMLs/analysis && unipept pept2lca -i peptides_cleaned.txt -e -o pept2lca.csv && unipept.R"
   ssh $headnode_user_ip 'cd '$output_folder' && echo "'$cmd'" | qsub -N MSnidFDRControlUnipept -P '$d_P' -q '$d_q' -l '$d_l' -l walltime=48:00:00'
    
fi

