#include<stdio.h>
#include<unistd.h>
#include<stdlib.h>
#include<signal.h>

#define PASSWORD  0         // decalage pour acceder au password enregistre dans prepare
#define RETADDR   0         // decalage pour acceder a l'adresse de retour dans launch


/*

Step 1 : faire planter le prog
Step 2 : modifier le mdp dans la variable juste au dessus, dans la pile (prepare)
Step 3 : modifier l'adresse de retour vers une autre fonction existante, ex code appelle armageddon() si mdp valide, retourne sinon : mettre l'adresse de retour à &service (launch)
Step 4 : exécution de code arbitraire via read

Générer la payload : printf '\x27\x85\x04\x08' > payload
			payload > payload2
			payload >> payload2    etc.

*/


int getPassword();
int armageddon();
int launch();
int prepare();
char* passwordfile;
void manage_signal(int sig);
char* data = "/bin/bash";

// A : Fonction de preparation
// Demande le code PIN
// Ici, modifier le mdp a reconnaitre
int prepare() {
	int goodpass = getPassword();
	char buffer[5];                                // Buffer à exploiter

	// Etat au début
	printf("\n\n--DEBUG-- buffer address = %x\n",(unsigned int)buffer);
	fprintf(stderr,"--DEBUG-- Expected PIN = %d\n",*(int*)(buffer+PASSWORD));  // def PASSWORD

	printf("To prepare the system, enter the PIN Code (4 digits)\n");
	scanf("%s",(char*) &buffer);                   // Pas de vérification de longueur ici
	int mdp = (*((int*)buffer));

	// Etat après la saisie
	printf("--DEBUG-- buffer address = %x\n",(unsigned int)buffer);
	fprintf(stderr,"--DEBUG-- Expected PIN = %d\n",*(int*)(buffer+PASSWORD));   // def PASSWORD
	printf("--DEBUG-- Entered PIN = %d\n",mdp);


	if (mdp == goodpass) {
		printf("Authentication succeeded !\n");
		return launch(passwordfile);
	}
	else
		printf("Authentication failed !\n");

	return -1;
}

// B : Fonction de lancement
// Accessible uniquement après validation du code PIN
// Ici, modifier l'adresse de retour
int launch() {
	char buffer[5];                                // Buffer à exploiter
	//int goodpass = getPassword();

	// Etat au début
	printf("\n\n--DEBUG-- buffer address = %x\n",(unsigned int)buffer);
	printf("--DEBUG-- return address = %x\n",*(int*)(buffer+RETADDR));  // def RETADDR

	printf("Ready to launch ! Please enter the PIN Code again to confirm (4 digits)\n");
	scanf("%s",(char*) &buffer);                   // Pas de vérification de longueur ici
	int mdp = (*((int*)buffer));

	// Etat après la saisie
	printf("--DEBUG-- buffer address = %x\n",(unsigned int)buffer);
	printf("--DEBUG-- return address = %x\n",*(int*)(buffer+RETADDR));   // def RETADDR
	printf("--DEBUG-- Entered PIN = %d\n",mdp);


	if (mdp == getPassword()) {
		printf("Authentication succeeded !\n");
		return armageddon();
	}
	else
		printf("Authentication failed !\n");

	return -1;
}

// C : Lancement de la guerre
int armageddon() {
	printf("\n\nArmageddon !!!\n\n\n");
	//execl("/bin/bash", "/bin/bash", "-c", "touch /tmp/toto"); // virement

	return -1;
}


// Fonction de lecture du code PIN a reconnaitre
// Out : le code PIN à reconnaître
int getPassword() {
	char password[5];
	FILE* passfile = fopen(passwordfile,"r");
	if (passfile==NULL) {
		printf("Cannot open passfile !\n");
		return(-1);
	}
	fscanf(passfile, "%4s", (char*)&password);
	fprintf(stderr,"Loaded PIN Code is %s\n",password);
	return *((int*)password);
}


int main(int argc, char** argv) {
	setvbuf(stdout, NULL, _IONBF, 0);
	if (signal(13, manage_signal) == SIG_ERR)
	{
        	printf("Le gestionnaire de signal pour SIG_13 n'a pu etre defini.\n");
    	}

	if (argc < 2) {
		printf("Please give the password file as an argument (plaintext file)\n");
		return 1;	
	}
	passwordfile = argv[1];

	printf("\n\n--DEBUG--adresses de read=%x, system=%x, data=%x, main=%x, prepare=%x, launch=%x, armageddon=%x\n",(unsigned int)&read,(unsigned int)&system,(unsigned int)&data,(unsigned int)&main,(unsigned int)&prepare,(unsigned int)&launch,(unsigned int)&armageddon);
	printf("Welcome to the nuclear thermowar launching tool\n");

	while (prepare());

	printf("Bye !\n");

	return 0;

}

void manage_signal(int sig) {
	fprintf(stderr,"Signal %d received, exiting...\n",sig);
	exit(1);
}
