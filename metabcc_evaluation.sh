#!/bin/bash
function usage(){
echo "./metabcc_evaluation <MetaBCC_final_txt> <label> <topN>"
}

if [[ $# == 0 ]]; then
usage
exit 1
fi

result=$1
label=$2
topN=$3
total_reads_num=`wc -l ${result} | awk '{print $1}'`
total_human_reads_num=`grep ${label} ${result} | wc -l`

grep ${label} ${result} | sort -k2,2 | awk '{print $2}' | uniq -c | sort -nr -k1,1 >bin
bin_num=`wc -l bin | awk '{print $1}'`

declare -A bin
index=0
while read line
do
info=(${line//\t/})
bin["${index}"]=${info[1]}
index=$[index+1]
done < bin

if [[ -e bin.result ]]; then
rm bin.result
fi

for i in ${!bin[@]}
do
bin_name=${bin[$i]}
bin_human_reads_num=`grep ${label} ${result} | awk '{print $2}' | grep "^${bin_name}$" | wc -l`
bin_reads_num=`awk '{print $2}' ${result} | grep "^${bin_name}$" | wc -l`
precision=`awk 'BEGIN{printf "%.2f",'${bin_human_reads_num}'/'${bin_reads_num}' * 100}'`
recall=`awk 'BEGIN{printf "%.2f",'${bin_human_reads_num}'/'${total_human_reads_num}' * 100}'`
f1=`awk 'BEGIN{printf "%.2f",('${bin_human_reads_num}' * 2 / ('${bin_reads_num}' + '${total_human_reads_num}')) * 100}'`
printf "%s\t%s\t%s\t%s\t%s\t%s\n" ${bin_name} ${bin_human_reads_num} ${bin_reads_num} ${precision} ${recall} ${f1}>>bin.result
done

sort -nr -k6,6 bin.result >bin.result.sorted

head -n ${topN} bin.result.sorted >selected.bin.result
total_selected_bin_reads_num=`awk 'BEGIN{sum=0}{sum+=$3}END{print sum}' selected.bin.result`
total_selected_bin_human_reads_num=`awk 'BEGIN{sum=0}{sum+=$2}END{print sum}' selected.bin.result`
precision=`awk 'BEGIN{printf "%.2f",'${total_selected_bin_human_reads_num}'/'${total_selected_bin_reads_num}' * 100}'`
recall=`awk 'BEGIN{printf "%.2f",'${total_selected_bin_human_reads_num}'/'${total_human_reads_num}' * 100}'`
f1=`awk 'BEGIN{printf "%.2f",('${total_selected_bin_human_reads_num}' * 2) / ('${total_human_reads_num}' + '${total_selected_bin_reads_num}') * 100}'`

echo "SUMMARY"
echo "Label			: ${label}"
echo "Total Reads		: ${total_reads_num}"
echo "Total ${label} Reads	: ${total_human_reads_num}"
echo "Total Bins		: ${bin_num}"
echo "Precision(%)		: ${precision}"
echo "Recall(%)		: ${recall}"
echo "F1 score(E-02)		: ${f1}"
echo ""
echo "bin-id	bin-${label}-reads-num	bin-reads-num	precision(%)	recall(%)	f1(E-02)"
cat bin.result.sorted

rm bin
rm bin.result
rm bin.result.sorted
rm selected.bin.result
