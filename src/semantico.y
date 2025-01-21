%{
#define _GNU_SOURCE
// Se meten las librerias necesarias: libreria estandar de c y la lista de simbolos para gesationar variables.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "listaSimbolos.h"
#include "listaCodigo.h"
#include <stdbool.h>
//Inicialización de la funcion de error: responable del estado de pánico posteriormente
void yyerror(const char *s);


// Variables externas de flex
extern int yylex();
	//Número de linea
extern int yylineno;
	//Texto leido
extern char* yytext;
void yyerror(const char *s);

//Número de errores léxicos.
extern int errores_lexicos;
int errores_sintacticos = 0;
int errores_semantico = 0;

//Función a la que se llama para el tratamiento de errores sintácticos
void erroresSintacticos();
//Función que devuelve 0 si no hay errores 1 si los hay.
int hayErrores();
//Tabla de símbolos para análisis semántico:
Lista tablaSim;
// Tipo actual para análisis sintáctico
Tipo tipo;


//Funcionaliad de flujo de programa
void inicioPrograma();
void finPrograma();

//Comprobacion semánticas de ID

void comprobarId(char* nombre);
void comprobarIdLectura(char * nombre);
void comprobarIdEscritura(char* nombre);




//Funcionalidad de creacion de código

void generarCodigo(ListaC codigo);

//Contador de cadenas para generar nombres unívocos
int contadorCadenas = 1;
//Contador de etiquedas para generar etiquetas unívocas
int contadorETIQS = 1;
//Función para concatenar dos cadenas de caracteres.
char * concatenar(char * c1, char * c2);

//Función para mantener los registros actualizados
int registros[10];
char * obtenerReg();
void liberarReg(char * reg);

//Funciones de traducción:
ListaC traduccionASIG(ListaC lista, char * id);
ListaC traduccionNUM(int n);
ListaC traduccionID(char * id);
ListaC traduccionOPER(ListaC izq, ListaC der, char * instruccion);
ListaC traduccionIF(ListaC expresion, ListaC statement);
ListaC traduccionIF_ELSE(ListaC expresion, ListaC statement1, ListaC statement2);
ListaC traduccionWHILE(ListaC expresion, ListaC statement);
ListaC traduccionDOWHILE(ListaC expresion, ListaC statement);
ListaC traduccionASIG_VACIO(char * id);
ListaC traduccionNEG(ListaC lista);

ListaC printString(char * string, ListaC codigo);
ListaC printExpresion(ListaC expresion);
ListaC readID(ListaC expresion, char * id);

%}

%union{
	int entero;
	char *cadena;
	ListaC codigo;
}
// Con este define Bison da más información del fallo Sucedido
%define parse.error verbose
%expect 1
// Los tokens posteriormente utilizados:
%token PARI PARD CLLAVE ALLAVE COMA PTCOMA IGUAL 
%token IF ELSE READ WHILE PRINT VAR CONST DO

%token <entero> NUM
%token <cadena> STRING ID
// El orden de prioridad que se quiere que tengan
%left OR AND
%left MENOR MAYOR MAYIGUAL MENIGUAL
//Las operaciones comparativas son las que tienen menor orden de precedencia
%left MAS MENOS
%left POR DIV MOD  
%left UMENOS

// Expresion de tipo lista de código
%type <codigo> identifier_list declarations expresion statement statement_list print_list print_item read_list identifier  
//Las librerías que requiere el código.
%code requires{
	#include "listaSimbolos.h"
	#include "listaCodigo.h"
    #include <stdarg.h>
    #include <stdio.h>
}
%%
program 		: {inicioPrograma();} ID PARI PARD ALLAVE declarations  statement_list CLLAVE {if (!hayErrores()){concatenaLC($6,$7); liberaLC($7); finPrograma($6);} liberaLS(tablaSim);}
        		;
       			 // Para saber si la declaracion ha sido tomada como correcta se asigna a la varaible tipo
declarations 	: declarations VAR   {tipo =  VARIABLE;} identifier_list PTCOMA  	{if (!hayErrores()){$$ = $1; concatenaLC($1,$4); liberaLC($4);}} //$$ = $1;concatenaLC($$,$3);liberaLC($3);}
                | declarations CONST {tipo =  CONSTANTE;} identifier_list PTCOMA	{if (!hayErrores()){$$ = $1; concatenaLC($1,$4); liberaLC($4);}} 
                | %empty  {if (!hayErrores()) $$ = creaLC();}// Puede no haber ningún elemento declarado.
                ;

identifier_list	: identifier						{if (!hayErrores()){$$ = $1;}}
				| identifier_list COMA identifier	{if (!hayErrores()){$$ = $1; concatenaLC($1,$3); liberaLC($3);}}
				;
				// Si no se asignan a nada automáticamente se asignarán a 0.
identifier 		: ID 					{comprobarId($1); if (!hayErrores()) $$ = traduccionASIG_VACIO($1);}
				| ID IGUAL expresion 	{comprobarId($1); if (!hayErrores()) $$ = traduccionASIG($3, $1);} // Hacer algo mas
				;
				//No se crea código hasta ese momnento
statement_list 	: statement_list statement	{if (!hayErrores()) {concatenaLC($1, $2); $$ = $1;}}
				| %empty {if (!hayErrores()){$$ = creaLC();}}/* Equivalente a lambda */
				;
				//Para todos estos elementos comprobar que no eestén declaradas anteriormente.
statement 		: ID IGUAL expresion PTCOMA 									{comprobarIdEscritura($1);if (!hayErrores()) $$ = traduccionASIG($3, $1);}
				| ALLAVE statement_list CLLAVE 									{if (!hayErrores()) $$ = $2;} 	//Para cada caso 
				| IF PARI expresion PARD statement ELSE statement 				{if (!hayErrores()) $$ = traduccionIF_ELSE($3,$5,$7);}
				| IF PARI expresion PARD statement 								{if (!hayErrores()) $$ = traduccionIF($3,$5);}
				// Do while()
				// For.
				| DO statement WHILE PARI expresion PARD PTCOMA 				{if (!hayErrores()) $$ = traduccionDOWHILE($2,$5);}
				| WHILE PARI expresion PARD statement 							{if (!hayErrores()) $$ = traduccionWHILE($3,$5);}
				| PRINT PARI print_list PARD PTCOMA 							{if (!hayErrores()) $$ = $3;}
				| READ PARI read_list PARD PTCOMA 								{if (!hayErrores()) $$ = $3;}
				| error PTCOMA													{erroresSintacticos();}		
				//Estado pánico: hasta que encuentre una punto y coma si no coincide
				;
print_list 		: print_item						{if (!hayErrores()) $$ = $1;}
				| print_list COMA print_item		{if (!hayErrores()) {concatenaLC($1,$3); $$ = $1; liberaLC($3);}}
				;
				// Casos diferentes para imprimir una expresión a imprimir un string.
print_item 		: expresion							{if (!hayErrores()) $$ = printExpresion($1);}//
				| STRING 							{if (!hayErrores()) $$ = printString($1, creaLC());} // Meter los strings tabla de simbolos.
				;
				// Hay que comprobar antes siempre que 
read_list 		: ID								{comprobarIdEscritura($1); if (!hayErrores()) $$ = readID(creaLC(), $1);}
				| read_list COMA ID					{comprobarIdEscritura($3); if (!hayErrores()) $$ = readID($1, $3);}
				;
				// Expresiones: en cada una hay que comprobar que no existan errores antes de generar código
				// para evitar problemas de accesos a memoria inválidos.
expresion 		: expresion MAS expresion 			{if (!hayErrores()) $$ = traduccionOPER($1,$3,"add");}
				| expresion MENOS expresion 		{if (!hayErrores()) $$ = traduccionOPER($1,$3,"sub");}
				| expresion POR expresion 			{if (!hayErrores()) $$ = traduccionOPER($1,$3,"mul");}
				| expresion DIV expresion 			{if (!hayErrores()) $$ = traduccionOPER($1,$3,"div");}
				| expresion MOD expresion 			{if (!hayErrores()) $$ = traduccionOPER($1,$3,"mod");}
				| expresion MENOR expresion 		{if (!hayErrores()) $$ = traduccionOPER($1,$3,"slt");}
				| expresion MAYOR expresion 		{if (!hayErrores()) $$ = traduccionOPER($1,$3,"sgt");}
				| expresion MENIGUAL expresion 		{if (!hayErrores()) $$ = traduccionOPER($1,$3,"sle");}
				| expresion MAYIGUAL expresion 		{if (!hayErrores()) $$ = traduccionOPER($1,$3,"sge");}
				| expresion AND expresion 			{if (!hayErrores()) $$ = traduccionOPER($1,$3,"and");}
				| expresion OR expresion 			{if (!hayErrores()) $$ = traduccionOPER($1,$3,"or");}
				//Mejoras de operaciones
				| PARI expresion PARD 				{if (!hayErrores()) $$ = $2;}
				| MENOS expresion %prec UMENOS 		{if (!hayErrores()) $$ = traduccionNEG($2);}
				| ID								{comprobarIdLectura($1); if (!hayErrores()) $$ = traduccionID($1);} //Comprobar que el identificador pertenece a la tabla de símbolos 
				| NUM								{if (!hayErrores()) $$ = traduccionNUM($1);}
				;
%%
//Funciones de error
void yyerror(const char *s)
{
	//Si ha llegado un error,
	errores_sintacticos++;
	printf("Se ha producido un error en esta expresion: %s\n en la línea %d\n", s, yylineno);
}
void erroresSintacticos()
{
	errores_sintacticos++;
	printf("Se ha producido un error, sentencia no reconocida en la línea %d\n", yylineno);
}
int hayErrores()
{
	return !(errores_lexicos == 0 && errores_sintacticos == 0 && errores_semantico == 0);
}

//Antes de nada se crea la tabla de símbolos
// La creación de la tabla de código no se tiene que hacer aquí.
void inicioPrograma()
{
	tablaSim = creaLS();
}
// Cuando se acaba el programa hay que liberar
void finPrograma(ListaC codigo)
{
	//Si no se ha producido ningún fallo.
	generarCodigo(codigo);
	liberaLC(codigo);

}
void generarCodigo(ListaC codigo)
{
	//Si hay errores no se puede generar código.
	if(hayErrores())
    {
        printf("Fallos lexico: %d, sintactico : %d, semantico: %d \n", errores_lexicos, errores_sintacticos, errores_semantico);
		return;
    }
	
	printf("#######################\n# DATOS\n");
	
	//CADENA DE TEXTO QUE IDENTIFICA QUE COMIENZA LA DECLARACIÓN DE DATOS:
	printf("\t.data\n\n");

	PosicionLista pos = inicioLS(tablaSim);
	for(int j=0;j<longitudLS(tablaSim);j++){
		Simbolo simbolo = recuperaLS(tablaSim, pos);

		// La impresión es diferente si es una cadena o una constante/variable.
		if(simbolo.tipo == CADENA){
			printf("$str%d:\n", simbolo.valor);
			printf("\t.asciiz%s\n", simbolo.nombre);	
		}
		else
		{
			printf("_%s:\n", simbolo.nombre);
			printf("\t.word 0\n");	
		}
		pos = siguienteLS(tablaSim, pos);
	}
	printf("\n############################\n# CÓDIGO\n");

	// CADENA DE TEXTO QUE IDENTIFICA EL COMIENZO DEL PROGRAMA
	printf("\t.text\n");
	printf("\t.globl main\n");
	printf("main:\n");

	PosicionListaC p = inicioLC(codigo);
	while (p != finalLC(codigo)) {
		Operacion oper = recuperaLC(codigo,p);
		//Si es una etiqueta hay que imprimirlo de manera diferente
		if(strcmp(oper.op,"label") != 0){
			printf("\t%s",oper.op);
			if (oper.res) printf(" %s",oper.res);
			if (oper.arg1) printf(", %s",oper.arg1);
			if (oper.arg2) printf(", %s",oper.arg2);
		}else
			// la etiqueda debe ser impresa como $labeln: siendo n el número suyo
			printf("%s:", oper.res);
		printf("\n");
		p = siguienteLC(codigo,p);
	}
	//SALIDA
	printf("\n##################\n #Final: exit\n");
	//SYSCALL PARA CERRAR EJECUCIÓN
	printf("\tli $v0, 10\n");
	printf("\tsyscall\n");
}

void comprobarId(char* nombre)
{
	//Si el elemento actual no se ha introducido en la tabla de símbolos se introduce
	if (!perteneceLS(tablaSim, nombre))
	{
		Simbolo aux = {nombre, tipo};
		insertaLS(tablaSim, finalLS(tablaSim), aux);
		return;
	}

	//Si se ha metido en el cuerpo del if significa que la constante se ha declarado ya anteriormente
	errores_semantico++;
	char * tipoRepetido = (tipo == CONSTANTE) ? "constante" : "variable";
	printf("Error semántico en la línea %d, la %s %s ha sido declarada anteriormente\n", yylineno, tipoRepetido, nombre);
}
void comprobarIdLectura(char * nombre)
{
	if (perteneceLS(tablaSim, nombre))
		return;
	errores_semantico++;
	printf("Error semántico en la línea %d, la ID %s no ha sido declarada anteriormente\n", yylineno, nombre);
}
void comprobarIdEscritura(char * nombre)
{
    
	PosicionLista EA = buscaLS(tablaSim, nombre);
	if(EA == finalLS(tablaSim))
	{
		errores_semantico++;
		printf("Error semántico en la línea %d, la ID %s no ha sido declarada anteriormente", yylineno, nombre);
		return;
	}
    Simbolo simb = recuperaLS(tablaSim,EA);
	if (simb.tipo == CONSTANTE)
	{
		errores_semantico++;
		printf("Error semántico en la línea %d, la constante %s no puede cambiar su valor\n", yylineno, nombre);
	}
}

char * obtenerReg()
{
	for (int i = 0; i < 10; i++)
		if (!registros[i])
		{
			registros[i] = true;
			char * num;
			asprintf(&num, "%d", i);
			return concatenar("$t",num);
		}
	//Si se ha llegado fuera entonces es que no hay ninguno libre, por lo que se tiene que gestionar;
}
void liberarReg(char * reg)
{
	//En la posición 2 del registro estará: para $tn, se obtiene n que se pasará a atoi;
	registros[atoi(&reg[2])] = 0;
}
// Al ser un número la operación que debe realizar es: 
ListaC traduccionNUM(int n)
{
	ListaC num = creaLC();
	//Operacion oper = {"li", obtenerReg(), n, NULL};
	
	Operacion oper;
	oper.op = "li";
	oper.res = obtenerReg();
	char * regis;
	asprintf(&regis, "%d", n);
	oper.arg1 = regis;
	oper.arg2 = NULL;
	insertaLC(num, finalLC(num), oper);
	guardaResLC(num, oper.res);
	return num;
}
//El identificador del id se pasa por parámetro
ListaC traduccionID(char * id)
{
	ListaC num = creaLC();
	Operacion oper;
	oper.op = "lw";
	oper.res = obtenerReg();
	oper.arg1 = concatenar("_",id);
	oper.arg2 = NULL;
	insertaLC(num, finalLC(num), oper);
	guardaResLC(num, oper.res);
	return num;
}
//Esta no devuelve ninguna lista, a diferencia de las dos anteriores
// Se modifica la Lista de la izquierda
ListaC traduccionOPER(ListaC izq, ListaC der, char * instruccion)
{
	//Se concatenan las operaciones izquierda y derecha,
	concatenaLC(izq,der);
	Operacion oper;

	oper.op = instruccion;
	//El resultado se almacenará en el registro del resultado de la parte izquierda
	oper.res = recuperaResLC(izq);
	oper.arg1 = recuperaResLC(izq);
	oper.arg2 = recuperaResLC(der);
	
	//Cuando ya se ha inicializado la operación se inserta al final de la Lista derecha
	insertaLC(izq, finalLC(izq), oper);
	//Como el registro de la derecha no se va a usar más, se libera.
	liberarReg(recuperaResLC(der));
	// Como concatenaLC copia los elementos hay que liberar los de la derecha
	liberaLC(der);
	// Se devuelve la izquierda, que es donde se ha concatenado la nueva operación.
	return izq;
}
char * concatenar(char * c1, char * c2)
{
	char * aux;
	asprintf(&aux, "%s%s", c1, c2);
	return aux;
}

ListaC traduccionNEG(ListaC lista)
{
	//Se niega el el resultado del último registro
	Operacion oper;
	oper.op = "neg";
	oper.res = recuperaResLC(lista);
	oper.arg1 = oper.res;
	oper.arg2 = NULL;
	insertaLC(lista, finalLC(lista), oper);
	return lista;
}

ListaC traduccionASIG(ListaC lista, char * id)
{
	Operacion oper;
	oper.op = "sw";
	oper.res = recuperaResLC(lista);
	oper.arg1 = concatenar("_",id);
	oper.arg2 = NULL;
	insertaLC(lista,finalLC(lista),oper);
	//Como el valor ya se ha guardado en la posición del ID se puede liberar su registro.
	liberarReg(oper.res);
	return lista;
}

ListaC traduccionASIG_VACIO(char * id)
{
	ListaC devolver = creaLC();
	Operacion oper;
	oper.op = "sw";
	oper.res = "$zero";
	oper.arg1 = concatenar("_",id);
	oper.arg2 = NULL;
	insertaLC(devolver,finalLC(devolver),oper);
	//Como el valor ya se ha guardado en la posición del ID se puede liberar su registro.
	return devolver;
}
ListaC printString(char * string, ListaC codigo)
{
	Simbolo simobolo = {string, CADENA, contadorCadenas};

	insertaLS(tablaSim, finalLS(tablaSim), simobolo);
	//Aumentamos la etiqueta

	ListaC devolver = creaLC();
	//ListaC devolver = syscall(4);

	Operacion oper;
	oper.op = "li";
	oper.res =  "$v0";
	oper.arg1 = "4";
	oper.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), oper);
	guardaResLC(devolver, oper.res);

	Operacion oper2;
	oper2.op = "la";
	oper2.res =  "$a0";
	char * num;
	asprintf(&num, "%d", contadorCadenas);
	oper2.arg1 = concatenar("$str", num);
	oper2.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), oper2);
	guardaResLC(devolver, oper2.res);

    contadorCadenas++;

	Operacion oper3;
	oper3.op = "syscall";
	oper3.res =  NULL;
	oper3.arg1 = NULL;
	oper3.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), oper3);

	concatenaLC(codigo,devolver);
	return codigo;
}

ListaC printExpresion(ListaC expresion)
{
	ListaC devolver = creaLC();
	//ListaC devolver = syscall(1);

	Operacion oper;
	oper.op = "li";
	oper.res =  "$v0";
	oper.arg1 = "1";
	oper.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), oper);
	guardaResLC(devolver, oper.res);

	Operacion oper2;
	oper2.op = "move";
	oper2.res =  "$a0";
	oper2.arg1 = recuperaResLC(expresion);
	oper2.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), oper2);
	guardaResLC(devolver, oper2.res);

	Operacion oper3;
	oper3.op = "syscall";
	oper3.res =  NULL;
	oper3.arg1 = NULL;
	oper3.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), oper3);
	
	concatenaLC(expresion,devolver);
	return expresion;
}
// La diferencia entre comprobar escritura y lectura es
ListaC readID(ListaC expresion, char * id)
{
	ListaC devolver = creaLC();
	//ListaC devolver = syscall(1);

	Operacion oper;
	oper.op = "li";
	oper.res =  "$v0";
	oper.arg1 = "5";
	oper.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), oper);
	guardaResLC(devolver, oper.res);


	Operacion oper3;
	oper3.op = "syscall";
	oper3.res =  NULL;
	oper3.arg1 = NULL;
	oper3.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), oper3);
	
	Operacion oper2;
	oper2.op = "sw";
	oper2.res =  "$v0";
	oper2.arg1 = concatenar("_",id);
	oper2.arg2 = NULL;

	insertaLC(devolver, finalLC(devolver), oper2);
	guardaResLC(devolver, oper2.res);
	concatenaLC(expresion,devolver);
	return expresion;
}
char * generarEtiq()
{
	char * etiqueta;
	asprintf(&etiqueta, "$label%d", contadorETIQS);
	contadorETIQS++;
	return etiqueta;
}
ListaC traduccionWHILE(ListaC expresion, ListaC statement)
{
	ListaC devolver = creaLC();
	 // Generar etiqueta
	char* inicio = generarEtiq();
	char* fin = generarEtiq();

	Operacion inicioOp;
	inicioOp.op = "label";
	inicioOp.res =  inicio;
	inicioOp.arg1 = NULL;
	inicioOp.arg2 = NULL;

	insertaLC(devolver, finalLC(devolver), inicioOp);
	guardaResLC(devolver, inicioOp.res);
	
	concatenaLC(devolver,expresion);

	
	Operacion condicion;
	condicion.op = "beqz";
	condicion.res =  recuperaResLC(expresion);
	condicion.arg1 = fin;
	condicion.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), condicion);
	guardaResLC(devolver, condicion.res);
	
	concatenaLC(devolver,statement);

	Operacion salto;
	salto.op = "b";
	salto.res =  inicio;
	salto.arg1 = NULL;
	salto.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), salto);
	guardaResLC(devolver, salto.res);

	Operacion finOp;
	finOp.op = "label";
	finOp.res =  fin;
	finOp.arg1 = NULL;
	finOp.arg2 = NULL;

	insertaLC(devolver, finalLC(devolver), finOp);
	guardaResLC(devolver, finOp.res);
	
	liberarReg(recuperaResLC(expresion));
		liberaLC(expresion);
		liberaLC(statement);
	return devolver;
}
ListaC traduccionDOWHILE(ListaC statement, ListaC expresion)
{
	ListaC devolver = creaLC();
	// Generar etiqueta
	char* inicio = generarEtiq();

	Operacion inicioOp;
	inicioOp.op = "label";
	inicioOp.res =  inicio;
	inicioOp.arg1 = NULL;
	inicioOp.arg2 = NULL;

	insertaLC(devolver, finalLC(devolver), inicioOp);
	guardaResLC(devolver, inicioOp.res);
	
	concatenaLC(devolver, statement);
	concatenaLC(devolver,expresion);

	Operacion condicion;
	condicion.op = "bnez";
	condicion.res =  recuperaResLC(expresion);
	condicion.arg1 = inicio;
	condicion.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), condicion);
	guardaResLC(devolver, condicion.res);
	
	liberarReg(recuperaResLC(expresion));
	liberaLC(expresion);
	liberaLC(statement);

	return devolver;
}
ListaC traduccionIF(ListaC expresion, ListaC statement)
{	

	ListaC devolver = expresion;
	// Generar etiqueta
	char* etiqueta = generarEtiq();
	

	Operacion oper;
	oper.op = "beqz";
	oper.res =  recuperaResLC(expresion);
	oper.arg1 = etiqueta;
	oper.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), oper);
	guardaResLC(devolver, oper.res);
	
	liberarReg(recuperaResLC(expresion));

	concatenaLC(devolver,statement);
	liberaLC(statement);

	Operacion etiq;
	etiq.op = "label";
	etiq.res =  etiqueta;
	etiq.arg1 = NULL;
	etiq.arg2 = NULL;

	insertaLC(devolver, finalLC(devolver), etiq);
	guardaResLC(devolver, etiq.res);

	return devolver;
}
ListaC traduccionIF_ELSE(ListaC expresion, ListaC statement1, ListaC statement2)
{	

	ListaC devolver = expresion;
	// Generar etiqueta
	char * etiqueta = generarEtiq();
	char * etiqElse = generarEtiq();

	Operacion oper;
	oper.op = "beqz";
	oper.res =  recuperaResLC(expresion);
	oper.arg1 = etiqueta;
	oper.arg2 = NULL;
	insertaLC(devolver, finalLC(devolver), oper);
	guardaResLC(devolver, oper.res);
	
	liberarReg(recuperaResLC(expresion));

	concatenaLC(devolver,statement1);
	liberaLC(statement1);

	Operacion salto;
	salto.op = "b";
	salto.res = etiqElse;
	salto.arg1 = NULL;
	salto.arg2 = NULL;

	insertaLC(devolver,finalLC(devolver), salto);

	Operacion etiq;
	etiq.op = "label";
	etiq.res =  etiqueta;
	etiq.arg1 = NULL;
	etiq.arg2 = NULL;

	insertaLC(devolver, finalLC(devolver), etiq);

	concatenaLC(devolver, statement2);
	liberaLC(statement2);

	Operacion labelElse;
	labelElse.op = "label";
	labelElse.res =  etiqElse;
	labelElse.arg1 = NULL;
	labelElse.arg2 = NULL;

	insertaLC(devolver, finalLC(devolver), labelElse);
	guardaResLC(devolver, etiq.res);

	return devolver;
}