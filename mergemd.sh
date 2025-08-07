#!/usr/bin/env bash

INPUT_DIR="./content/zh/"
OUTPUT_FILE="./output/merged.md"

MD_FILES=(
  "preface.md"
  "toc.md"
  "part-i.md"
  "ch1.md"
  "ch2.md"
  "ch3.md"
  "ch4.md"
  "part-ii.md"
  "ch5.md"
  "ch6.md"
  "ch7.md"
  "ch8.md"
  "ch9.md"
  "part-iii.md"
  "ch10.md"
  "ch11.md"
  "ch12.md"
  "colophon.md"
  "glossary.md"
)

# 清空输出文件
> "$OUTPUT_FILE"

for ((i=0; i<${#MD_FILES[@]}; i++)); do
  file="${MD_FILES[i]}"
  fullpath="${INPUT_DIR}/${file}"

  if [[ -f "$fullpath" ]]; then
    # 去除多余空行并追加到输出文件
    awk 'NF{blank=0; print; next} !blank{print ""; blank=1}' "$fullpath" >> "$OUTPUT_FILE"

    # 插入分页符（不是最后一个文件）
    if [[ $i -lt $((${#MD_FILES[@]} - 1)) ]]; then
      cat <<EOF >> "$OUTPUT_FILE"

:::pagebreak
:::

EOF
    fi
  else
    echo "⚠️ Warning: file $fullpath not found!"
  fi
done

echo "✅ Merged markdown file created at: $OUTPUT_FILE"

