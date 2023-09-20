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

fstinvert compiled/pt2en.fst > compiled/en2pf.fst

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

# #1 - generates files
# echo "\n***********************************************************"
# echo "Testing 4 (the output is a transducer: fst and pdf)"
# echo "***********************************************************"
# for w in compiled/t-*.fst; do   

#     # extract name from w:
#     # file_path=$w
#     # filename=$(basename "$file_path")
#     # filename_without_extension="${filename%.fst}"
#     # filename_without_prefix="${filename_without_extension#t-}"
#     # "compiled/$filename_without_prefix.fst"

#     # THE FILE IS HARD CODED HERE 
#     fstcompose $w compiled/mmm2mm.fst | fstshortestpath | fstproject --project_type=output |
#                   fstrmepsilon | fsttopsort > compiled/$(basename $i ".fst")-out.fst
# done
# for i in compiled/t-*-out.fst; do
# 	echo "Creating image: images/$(basename $i '.fst').pdf"
#    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
# done


# #2 - present the output as an acceptor
# echo "\n***********************************************************"
# echo "Testing 1 2 3 4 (output is a acceptor)"
# echo "***********************************************************"
# trans=n2text.fst
# echo "\nTesting $trans"
# for w in "1" "2" "3" "4"; do
#     echo "\t $w"
#     python3 ./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
#                      fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
#                      fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=syms.txt
# done

# #3 - presents the output with the tokens concatenated (uses a different syms on the output)
# fst2word() {
# 	awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}'
# }

# trans=n2text.fst
# echo "\n***********************************************************"
# echo "Testing 5 6 7 8  (output is a string  using 'syms-out.txt')"
# echo "***********************************************************"
# for w in 5 6 7 8; do
#     res=$(python3 ./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
#                        fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
#                        fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
#     echo "$w = $res"
# done

# echo "\nThe end"


# TESTING WITH V3

fst2word() {
	awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}'
}

trans=date2text.fst
test_string="OCT-/-3-1-/-2-0-2-5"
seperator="-"

# test_string="10/31/2025"
# seperator=""

echo "\n***********************************************************"
echo "Testing $test_string (output is a string  using 'syms-out.txt')"
echo "***********************************************************"
for w in $test_string; do

    res=$(python3 ./scripts/word2fst.py $w --separator=$seperator| fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                       fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                       fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
    echo "$w = $res"
done

echo "\nThe end"
