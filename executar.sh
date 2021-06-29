echo "Removendo arquivos antigos"
rm lex.yy.c
rm lex.yy.o
rm y.tab.h
rm y.tab.c
rm y.tab.o
echo "Compilando"
yacc -d grammar.y
lex lexic.l
gcc -c lex.yy.c y.tab.c
gcc -o parser lex.yy.o y.tab.o -ll
