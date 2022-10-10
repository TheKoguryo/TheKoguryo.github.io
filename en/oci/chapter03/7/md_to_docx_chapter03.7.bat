pandoc _index.md -o 0.docx
pandoc 1.md -o 1.docx
pandoc 2.md -o 2.docx
pandoc 3.md -o 3.docx
pandoc 4.md -o 4.docx

DocxMerge -i 0.docx 4.docx 3.docx 2.docx 1.docx -f -o chapter03.7.docx
