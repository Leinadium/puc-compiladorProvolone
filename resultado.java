import java.util.Scanner;

public class Resultado {
    public static void main(int argc, String[] argv) {
        Scanner _sc = new Scanner(System.in);
        System.out.printf("Entrada [X]:");
        int X = _sc.next();
        System.out.printf("Entrada [Y]:");
        int Y = _sc.next();
        int Z = 0;
        if (X){ 
            Z++;
        } else {
            if (Y){ 
                Z++;
                Z++;
            } else {
                Z++;
                Z++;
                Z++;
            }
        }
        System.out.printf("Saida: [Z] = %d\n", Z);
    }
}
