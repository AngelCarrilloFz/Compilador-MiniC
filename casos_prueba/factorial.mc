main() {
    //Inicialización de variables
    var n;
    var fact = 1;
    var i = 1;
    //Se obtiene el parámetro de entrada
    print("Introduce el número del que quieras conocer su factorial (numero < 0 para acabar ejecución): ");
    read(n);
    while ( n >= 0) {
    if (n < 2)
    {
        //Caso base
        fact = 1;
    } else {
        while(i<=n){
            fact = fact * i;
            i=i+1;
        }
    }
    print("El factorial de ",n," es ", fact , "\n");
    print("Introduce el número del que quieras conocer su factorial (numero < 0 para acabar ejecución): ");
    read(n);
    }
}