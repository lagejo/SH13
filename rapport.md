# Rapport - Projet OS User

Ce rapport donne des explications sur la complétion des différentes parties (serveur et client) ainsi que sur les notions abordées en TP. 
J'y ai mis des extraits de mon codes, que j'ai expliqués.
Il y a également à la fin quelques explications sur le makefile que j'ai réalisé.

## Complétion du code de server.c

Voici des explications sur la manière dont j'ai complété les parties manquantes du code du serveur. 

### Distribution des cartes et initialisation

Une fois que les 4 joueurs sont connectés, le serveur doit envoyer à chacun ses 3 cartes et les informations de son tableau personnel. 
Pour cela, j'ai ajouté le code suivant pour chaque joueur :

```c
sprintf(reply,"D %d %d %d ", deck[0], deck[1], deck[2]);
sendMessageToClient(tcpClients[0].ipAddress, tcpClients[0].port, reply);
for(i=0; i<=7; i++)
{
    sprintf(reply,"V 0 %d %d ", i, tableCartes[0][i]);
    sendMessageToClient(tcpClients[0].ipAddress, tcpClients[0].port, reply);
}
```
Ce code envoie d'abord un message "D" (pour Distribution) contenant les 3 indices de cartes attribués au joueur. 
Ensuite, pour chacune des 8 caractéristiques du jeu, il envoie un message "V" (pour Valeur) avec les informations du tableau correspondant. 
J'ai répété ce processus pour chaque joueur, en adaptant les indices.

Pour terminer l'initialisation, j'annonce à tous les joueurs quel est le joueur courant :

```c
sprintf(reply,"M %d", joueurCourant);
broadcastMessage(reply);
```
Le message "M" (pour Move) indique à tous les clients qui doit jouer maintenant.

Gestion des actions des joueurs
Une fois le jeu démarré (fsmServer=1), le serveur doit gérer trois types d'actions :

**Accusation (G)** : Un joueur accuse un suspect d'être le coupable. J'ai implémenté ce code :

```c
sscanf(buffer,"G %d %d", &id, &i);
if(i == deck[12])
{
    sprintf(reply, "Gagnat : %d !", id);
    broadcastMessage(reply);
    exit(0);
}
else
{
    sprintf(reply, "Perdu, %d n'est pas coupable, vous ne pouvez plus jouer", id);
    broadcastMessage(reply);
    joueurCourant++;
    if(joueurCourant == 4){
        joueurCourant = 0;
    }
    sprintf(reply,"M %d", joueurCourant);
    broadcastMessage(reply);
}
```

Le serveur vérifie si l'accusation est correcte (correspond à la 13ème carte). Si c'est le cas, le joueur gagne et la partie se termine. Sinon, il est éliminé et c'est au tour du joueur suivant.

**Question générale (O)** : Un joueur demande qui possède un certain symbole. Le code parcourt tous les joueurs et envoie les informations correspondantes.
```c
sscanf(buffer, "O %d %d", &id, &n);

// parcourir les clients
for (i = 0 ; i < 4 ; i++) {
    if (i != id) {
        if (tableCartes[i][n] > 0) {
            sprintf(reply, "V %d %d 100", i, n);
        }
        else {
            sprintf(reply, "V %d %d 0", i, n);
        }
        broadcastMessage(reply);
    }
}
```

**Question ciblée (S)** : Similaire à la question générale, mais pour une caractéristique spécifique.
```c
int objet;
// Solo, un joueur demandé à un seul joueur un symbole
sscanf(buffer,"S %d %d %d", &id, &i, &objet);

sprintf(reply, "V %d %d %d", i, objet, tableCartes[i][objet]);
```

### Utilisation des sockets

Pour la communication entre le serveur et les clients, j'ai utilisé des sockets TCP. Le serveur crée un socket avec :

```c
sockfd = socket(AF_INET, SOCK_STREAM, 0);
```

Il se met en écoute sur un port spécifique puis accepte les connexions entrantes avec `accept()`.

Pour envoyer des messages aux clients, j'ai utilisé deux fonctions :

1. `sendMessageToClient()` : envoie un message à un client spécifique
2. `broadcastMessage()` : envoie un message à tous les clients

Ces fonctions créent un nouveau socket pour chaque message, se connectent au client, envoient le message puis ferment la connexion.

### Gestion des processus

Le serveur fonctionne comme un processus unique qui gère tous les clients. Il utilise une machine à états (FSM) avec deux états principaux :

1. `fsmServer=0` : Attente des connexions des joueurs
2. `fsmServer=1` : Jeu en cours

Cette approche permet de gérer séquentiellement les actions sans avoir besoin de threads supplémentaires.


## Complétion du code de sh13.c

Pour compléter le code du client, j'ai dû implémenter plusieurs fonctionnalités pour permettre la communication avec le serveur et le bon déroulement du jeu.

### Connexion au serveur

L'initialisation du serveur s'affectue avec un numéro de port passé en argument au lancement. Un socket est créé (`sockfd = socket(AF_INET, SOCK_STREAM, 0);`)
puis il y a un `bind()` pour attacher la socket à l'adresse et au port donnés, puis on commence à écouter (`listen()`).

Au démarrage, le client doit se connecter au serveur. J'ai implémenté cette fonctionnalité quand l'utilisateur clique sur le bouton "Connect" :

```c
sprintf(sendBuffer,"C %s %d %s",gClientIpAddress,gClientPort,gName);
sendMessageToServer(gServerIpAddress,gServerPort,sendBuffer);
```
Ce code envoie un message au format "C [IP client] [Port client] [Nom]" au serveur, ce qui permet d'identifier le joueur et d'établir la connexion.

### Envoi des actions au serveur

J'ai implémenté trois types d'actions que le joueur peut effectuer pendant son tour :

**Accusation (G)** : Quand le joueur accuse un suspect d'être le coupable :

```c
sprintf(sendBuffer,"G %d %d",gId, guiltSel);
sendMessageToServer(gServerIpAddress, gServerPort, sendBuffer);
```
**Question générale (O)** : Quand le joueur interroge tous les joueurs sur un symbole :

```c
sprintf(sendBuffer,"O %d %d",gId, objetSel);
sendMessageToServer(gServerIpAddress, gServerPort, sendBuffer);
goEnabled = 0;
```

**Question ciblée (S)** : Quand le joueur interroge un joueur spécifique sur un symbole :

```c
sprintf(sendBuffer,"S %d %d %d",gId, joueurSel,objetSel);
sendMessageToServer(gServerIpAddress, gServerPort, sendBuffer);
goEnabled = 0;
```
Dans chaque cas, j'utilise la fonction `sendMessageToServer()` pour envoyer les commandes au serveur. Pour les questions, je désactive le bouton "Go" après l'action (`goEnabled = 0`).

---

### Traitement des messages du serveur
Pour traiter les messages reçus du serveur, j'ai implémenté cinq types de réponses :

1. **Message 'I'** : Le joueur reçoit son identifiant :
```c
sscanf(gbuffer,"I %d", &gId);
```

2. **Message 'L'** : Le joueur reçoit la liste des joueurs :
```c
sscanf(gbuffer,"L %s %s %s %s", gNames[0], gNames[1], gNames[2], gNames[3]);
```

3. **Message 'D'** : Le joueur reçoit ses trois cartes :
```c
sscanf(gbuffer,"D %d %d %d", &b[0], &b[1], &b[2]);
```

4. **Message 'M'** : Le joueur reçoit le numéro du joueur courant :
```c
sscanf(gbuffer,"M %d", &id);
goEnabled = (id == gId) ? 1 : 0;
```
Cette partie est importante car elle permet d'activer le bouton "Go" uniquement quand c'est au tour du joueur.

5. **Message 'V'** : Le joueur reçoit une valeur pour tableCartes :
```c
int result;
sscanf(gbuffer,"V %d %d %d ", &i, &j, &result);
// vérifie que la case est bien vide ou *
if (tableCartes[i][j]==-1 || tableCartes[i][j]==100) tableCartes[i][j]=result;
```

### Utilisation des sockets et des threads

Le client utilise un thread séparé (`fn_serveur_tcp`) pour écouter les messages provenant du serveur. Ce thread crée un socket serveur sur lequel le client écoute les messages entrants. 

Quand un message est reçu, il est stocké dans la variable gbuffer et le drapeau synchro est mis à 1 pour signaler au thread principal qu'un nouveau message est disponible.

Pour envoyer des messages au serveur, j'utilise la fonction `sendMessageToServer()` qui crée un socket client, se connecte au serveur, envoie le message et ferme la connexion.

La synchronisation entre les deux threads est assurée par la variable synchro et un mutex (`PTHREAD_MUTEX_INITIALIZER`) qui protège les accès concurrents à gbuffer.

## Explications sur le Makefile

Ce `Makefile` a été conçu pour faire les étapes suivantes :
1. **Création du dossier `dist`** : Si le dossier n'existe pas, il est créé pour stocker les exécutables.
2. **Compilation** : Les fichiers sources `.c` sont compilés en deux exécutables :

   - `dist/server` : Le serveur.
   - `dist/sh13` : Le client.

3. **Exécution** : Le serveur est lancé sur un port défini, et plusieurs clients se connectent à ce serveur.

4. **Nettoyage** : Les fichiers générés peuvent être supprimés pour nettoyer le projet.

---

### Variables

- **`TARGET` et `CLIENT`** : Définissent les chemins des exécutables générés :
  - `dist/server` pour le serveur.
  - `dist/sh13` pour le client.
- **`PORT`** : Définit le port sur lequel le serveur écoute (par défaut `43000`).
- **`SOURCES`** : Utilise `$(wildcard *.c)` pour récupérer automatiquement tous les fichiers `.c` du répertoire courant.

---

### Règles

#### `all`
La règle principale qui exécute les étapes suivantes :
1. Crée le dossier `dist` si nécessaire.
2. Compile les exécutables.
3. Lance le serveur et les clients.

#### `dist`
Crée le dossier `dist` avec la commande :
```bash
mkdir -p dist
```

L'option -p empêche les erreurs si le dossier existe déjà.

#### $(TARGET)
Compile les fichiers sources en deux exécutables :

dist/sh13 pour le client, avec les bibliothèques SDL2 nécessaires.
dist/server pour le serveur.

#### run
Lance le serveur et plusieurs clients :

- Serveur : ```@./$(TARGET) $(PORT) &```
Lance le serveur en arrière-plan (&) sur le port défini par $(PORT).
- Clients : ```@./$(CLIENT) ... &```
Lance chaque client en arrière-plan, en se connectant au serveur sur le port $(PORT), sous la forme : `./sh13 <IP address server> <Server port> <IP address client> <Client port> <Username>`

Chaque client utilise un port différent, calculé avec une commande shell en incrémentant de 1.
wait : Attend que tous les processus en arrière-plan se terminent avant de continuer.

#### clean

Supprime les fichiers générés pour nettoyer le projet :

```bash
rm -f $(TARGET)
```
