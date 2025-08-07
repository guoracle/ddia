#!/usr/bin/env bash

INPUT_DIR="./content/zh/"  # 修改为你的目录
OUTPUT_FILE="./output/merged.md"  # 合并后的文件路径

# 指定顺序的文件列表
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

# 先清空输出文件
> "$OUTPUT_FILE"

for ((i=0; i<${#MD_FILES[@]}; i++)); do
  file="${MD_FILES[i]}"
  fullpath="${INPUT_DIR}/${file}"

  if [[ -f "$fullpath" ]]; then
    cat "$fullpath" >> "$OUTPUT_FILE"
    # 不是最后一个文件时，插入分页符
    if [[ $i -lt $((${#MD_FILES[@]} - 1)) ]]; then
      echo -e '\\clearpage' >> "$OUTPUT_FILE"
    fi
  else
    echo "Warning: file $fullpath not found!"
  fi
done

echo "Merged markdown file created at: $OUTPUT_FILE"

