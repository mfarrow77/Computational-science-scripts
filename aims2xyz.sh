#!/bin/bash 
echo "**************************"
echo "      aims2xyz            "
echo "                          "
echo " Written by M.R.Farrow    "
echo "    V1.0   Sept 2015      " 
echo "**************************"

if [ -f $1.xyz ] ;then
   echo $1.xyz already exists, moving to $1.xyz.old
   mv $1.xyz $1.xyz.old
fi

# Are we converting a FHI-aims geometry file? 
if [ $1 == geometry.in ] || [ $1 == geometry.in.nextstep ]; then
   echo "FHI-aims geometry.in file being converted"
   cell=`grep -c lattice_vector $1`
   if [ "$cell" -gt "0" ]; then
      echo " "
      echo "**************************"
      echo "WARNING! bulk system detected - xyz file has no lattice information!" 
      echo "**************************"
      echo "  "
   fi
# Now to sort out the atom types and numbers   
   num_types=1
   counter=`grep -c "atom_frac" $1`
   if [ "$counter" -gt "0" ]; then
      echo " "
      echo "**************************"
      echo "ERROR! fractional coordinates  detected - xyz file will make no sense!" 
      echo "**************************"
      echo "  "
      exit
   fi
   counter=`grep atom $1 | wc -l`
   echo $counter atoms detected
   echo $counter >> $1.xyz
   echo Conversion from $1 input file >> $1.xyz
   type_1=`grep "atom " $1 | head -1 | awk '{print $5}'`
   echo Found $type_1 atom
   type_array[0]=`echo $type_1`
   for ((i=1 ; i <= $counter ; i++ ))
   do
     type_tmp=`grep atom $1 | awk '{print $5}'`
     type_2=`echo $type_tmp | awk -v val=$i '{print $val}'`
     match_flg=0
     for j in "${type_array[@]}" 
     do
       if [ "$type_2" == "$j" ]; then
          match_flg=1
       fi
     done 
     if [ "$match_flg" == "0" ]; then 
        num_types=$((num_types + 1))
        type_array[$num_types]=`echo $type_2`
        echo New atom type found, $type_2
        echo $num_types types found so far
     fi
     done
# Contine with xyz creation
    for i in "${type_array[@]}"
    do
      echo $i
      grep $i $1 | grep "atom" | awk '{printf("%c %f %f %f \n", $5,$2,$3,$4)}' >> $1.xyz
    done
#  if not, assumed to be FHI-aims output file
else
   echo "Assuming FHI-aims output file being converted"
   cell=`grep lattice_vector $1 | tail -3 | wc -l`
   if [ "$cell" -gt "0" ]; then
      echo "WARNING! bulk system detected - xyz file has no lattice information!" 
    fi
  check=`grep -c "Final atomic structure" $1` 
  if [ "$check" -eq "0" ]; then
    echo " "
    echo "*****************************"
    echo "ERROR! System is not converged."
    echo "*****************************"
    echo "  "
    exit
  fi

# Number of atoms    
    num=`grep "| Number of atoms" $1 | awk '{print $6}'`
    echo $num >> $1.xyz
# Get the energy
    en=`grep "Total energy uncorrected" $1 | awk '{print $6}'| tail -1`
    echo SCF Done $en >> $1.xyz
# Now to sort out the atom types and numbers   
   num_types=1
   counter=`grep "| Number of atoms " $1 | awk '{print $6}'` 
   echo $counter atoms detected
   type_1=`grep Species: $1 | head -1 | awk '{print $2}'`
   type_array[0]=`echo $type_1`
   type_tmp=`grep Species: $1 | awk '{print $2}'`
   num_types=`grep "Number of species " $1 | awk '{print $6}'`
   echo There are $num_types types of atoms
# Now to add the positions
  grep -A $((counter + 1 ))  "Final atomic structure" $1 | tail -$counter | awk '{print $5, $2, $3, $4}'>> $1.xyz 
fi
  echo New file $1.xyz created.
