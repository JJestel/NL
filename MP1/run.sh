#!/bin/zsh

mkdir -p compiled images

rm -f ./compiled/*.fst ./images/*.pdf

# ############ Compile source transducers ############
for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done

# ############ CORE OF THE PROJECT  ############

fstconcat compiled/mmm2mm.fst compiled/mix2numerical_dy.fst > compiled/mix2numerical.fst

fstinvert compiled/pt2en.fst > compiled/en2pt.fst

fstconcat compiled/month.fst compiled/slash.fst > compiled/temp0.fst
fstconcat compiled/temp0.fst compiled/day.fst > compiled/temp1.fst
fstconcat compiled/temp1.fst compiled/comma.fst > compiled/temp2.fst
fstconcat compiled/temp2.fst compiled/year.fst > compiled/datenum2text.fst
rm compiled/temp*.fst
rm compiled/slash.fst
rm compiled/comma.fst

fstcompose compiled/mix2numerical.fst compiled/datenum2text.fst > compiled/mix2text.fst

fstunion  compiled/mix2text.fst compiled/datenum2text.fst > compiled/date2text.fst

# ############ generate PDFs  ############
echo "Starting to generate PDFs"
for i in compiled/*.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done



# ############      3 different ways of testing     ############
# ############ (you can use the one(s) you prefer)  ############

#1 - generates files
echo "\n***********************************************************"
echo "Testing 'OCT/31/2025' and 'OUT/7/2025 with date2text.fst "
echo "(the output is a transducer: fst and pdf)"
echo "***********************************************************"
for w in compiled/t-*.fst; do   

    # NOTICE: the file is hard coded here 
    fstcompose $w compiled/date2text.fst | fstshortestpath | fstproject --project_type=output |
                  fstrmepsilon | fsttopsort > compiled/$(basename $w ".fst")-out.fst
done

for i in compiled/t-*-out.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done



#3 - presents the output with the tokens concatenated (uses a different syms on the output)
# Test the transducers mix2numerical.fst, en2pt.fst, datenum2text.fst, mix2text.fst, and date2text.fst with
# the dates on which the members of the working group turned 18.

fst2word() {
	awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}'
}

# test numeric and mixed format
bd1_mix="JUL/07/2014"
bd1_num="7/07/2014"
bd2_mix="OCT/1/2012"
bd2_num="10/1/2012"

echo "\n***********************************************************"
echo "Testing $bd1_mix, $bd1_num, $bd2_mix and $bd2_num \n(output is a string  using 'syms-out.txt')"
echo "***********************************************************"

for t in "mix2numerical.fst" "en2pt.fst" "datenum2text.fst" "mix2text.fst" "date2text.fst"; do
    echo "\nTesting $t"
    for w in $bd1_mix $bd1_num $bd2_mix $bd2_num; do

        res=$(python3 ./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                        fstcompose - compiled/$t | fstshortestpath | fstproject --project_type=output |
                        fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
        echo "$w = $res"
    done
done

echo "\nThe end"
