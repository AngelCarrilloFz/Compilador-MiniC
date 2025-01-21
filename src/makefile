miniC : main.c lex.yy.c semantico.tab.c listaCodigo.c listaSimbolos.c
	gcc main.c lex.yy.c semantico.tab.c listaCodigo.c listaSimbolos.c -lfl -o miniC

lex.yy.c: lexico.l semantico.tab.h
	flex lexico.l

semantico.tab.c semantico.tab.h: semantico.y listaCodigo.h listaSimbolos.h
	bison -d -v semantico.y 

clean:
	rm -rf *- lex.yy.c semantico.tab.* semantico.output compilador salida.s

run: miniC entrada.mc
	./miniC entrada.mc > salida.s 

valgrind : miniC entrada.mc
	valgrind  --leak-check=full ./miniC entrada.mc > salida.s
