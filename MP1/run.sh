#!/bin/zsh

mkdir -p compiled images

rm -f ./compiled/*.fst ./images/*.pdf

# ############ Compile source transducers ############
for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done

# ############ CORE OF THE PROJECT  ############

# concat mmm2mm and identity to create mix2numerical
# this would accept faulty data but as statesd in the project only valid dates are used
fstconcat compiled/mmm2mm.fst compiled/h_identity.fst > compiled/mix2numerical.fst


# invert pt2en to create en2pt
fstinvert compiled/pt2en.fst > compiled/en2pt.fst


# concat month, day and year to create datenum2text
# use helper transducers comma and slash in between
fstconcat compiled/month.fst compiled/h_slash.fst > compiled/temp0.fst
fstconcat compiled/temp0.fst compiled/day.fst > compiled/temp1.fst
fstconcat compiled/temp1.fst compiled/h_comma.fst > compiled/temp2.fst
fstconcat compiled/temp2.fst compiled/year.fst > compiled/datenum2text.fst
# remove temporary files
rm compiled/temp*.fst 
# rm compiled/slash.fst
# rm compiled/comma.fst


# compose mix2numerical and datenum2text to create mix2text
fstcompose compiled/mix2numerical.fst compiled/datenum2text.fst > compiled/mix2text.fst


# union of mix2text and datenum2text gives date2text
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

# test numeric and mixed format of birthdays
bd1_mix="JUL/25/2014"
bd1_num="07/25/2014"
bd2_mix="MAI/24/2018"
bd2_num="5/24/2018"

echo "\n***********************************************************"
echo "Testing 18th birthdays of group members (output is a string  using 'syms-out.txt')"
echo "***********************************************************"

for t in "mix2numerical.fst" "en2pt.fst" "datenum2text.fst" "mix2text.fst" "date2text.fst"; do
    echo "\nTesting: $t"
    for w in $bd1_mix $bd1_num $bd2_mix $bd2_num; do
        
        res=$(python3 ./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                        fstcompose - compiled/$t | fstshortestpath | fstproject --project_type=output |
                        fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
        echo "$w = $res"
    done
done

echo "\nThe end"




# Additional tests

echo "\n***********************************************************"
echo "Testing some more corner cases"
echo "***********************************************************"

for t in "date2text.fst"; do
    echo "\nTesting $t"
    for w in "FEV/1/2099" "2/01/2099"; do

        res=$(python3 ./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                        fstcompose - compiled/$t | fstshortestpath | fstproject --project_type=output |
                        fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
        echo "$w = $res"
    done
done

echo "\nThe end"

