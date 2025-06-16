# Documentation: Installation et Configuration du Plugin Vault pour Rundeck

## Introduction

Ce guide vous explique comment installer et configurer le plugin Vault pour Rundeck. Vous apprendrez à créer un AppRole via l'API BeAPI, à télécharger le plugin, et à configurer les droits nécessaires pour accéder aux secrets.

## Prérequis

* Accès à l'api BeAPI.
* Droits nécessaires pour modifier les politiques dans Vault.
* Rundeck installé et configuré.

## Création d'un AppRole via l'API BeAPI (Prérequis)

### Routes API

Pour créer un AppRole via l'API [BeAPI](https://beapi.dev.sgbt.lu:5000/v1/documentation), vous devez utiliser les routes suivantes :

1. **Création d'un AppRole**

   Pour créer un AppRole via l'API [BeAPI](https://beapi.dev.sgbt.lu:5000/v1/documentation), vous devez utiliser la route suivante :

   ```
   POST /vault/{cluster}/applications/{trigram}/{env}/approles
   ```
2. Conservez ces identifiants, car ils seront nécessaires pour configurer le plugin Vault dans Rundeck.

### Modification des Politiques et des Métadonnées

Ajoutez les métadonnées nécessaires à votre AppRole pour que Rundeck puisse lire les secrets :

```bash
path "secret/data/<replace_by_your_namespace>/*" {
  capabilities = ["read"]
}

path "secret/metadata/<replace_by_your_namespace>/*" {
  capabilities = ["list"]
}
```

Ceci est la configuration minimale requise.

## Téléchargement du Plugin Vault

1. Rendez-vous sur la page [GitHub de Rundeck](https://github.com/rundeck-plugins/vault-storage/releases).
2. Téléchargez la dernière version du plugin Vault.

   ```bash
   wget https://github.com/rundeck-plugins/vault-storage/releases/download/1.3.14/vault-storage-1.3.14.jar
   ```
3. Placez le fichier `.jar` du plugin dans le répertoire des plugins de Rundeck, généralement situé à `/var/lib/rundeck/libext`.

   ```bash
   sudo cp chemin/vers/le/plugin/vault-plugin.jar /var/lib/rundeck/libtext
   ```

## Configuration du Plugin Vault dans Rundeck

1. Ouvrez le fichier de configuration `rundeck-config.properties` situé dans le répertoire de configuration de Rundeck, généralement `/etc/rundeck`.
2. Ajoutez ou modifiez les lignes suivantes pour configurer l'accès à Vault :
   ```bash
   rundeck.storage.provider.1.type=vault-storage
   rundeck.storage.provider.1.path=keys/<rundeck_vault_namespace>
   rundeck.storage.provider.1.config.prefix=<vault_path_namespace>
   rundeck.storage.provider.1.removePathPrefix=true
   rundeck.storage.provider.1.config.secretBackend=secret
   rundeck.storage.provider.1.config.address=<vault_url>
   rundeck.storage.provider.1.config.engineVersion=2
   rundeck.storage.provider.1.config.storageBehaviour=vault

   # Auth via AppRole
   rundeck.storage.provider.1.config.authBackend=approle
   rundeck.storage.provider.1.config.approleAuthMount=approle
   rundeck.storage.provider.1.config.approleId=<your_role_id>
   rundeck.storage.provider.1.config.approleSecretId=<your_secret_id>

   # Timeouts (optionnel)
   rundeck.storage.provider.1.config.maxRetries=5
   rundeck.storage.provider.1.config.retryIntervalMilliseconds=1000
   rundeck.storage.provider.1.config.openTimeout=3500
   rundeck.storage.provider.1.config.readTimeout=3500
   ```
3. Remplacez les variables `<______>` par les valeurs réelles
   1. <rundeck_vault_namespace> : Ce sera le nom du dossier qui reflète le namespace Vault côté Rundeck. Vous êtes libres de choisir le nom que vous souhaitez, mais il est conseillé d'utiliser le même namespace que celui de Vault.
   2. <vault_path_namespace>: Remplacer par le namespace Vault associé à l'AppRole.
   3. <vault_url>: Remplacer par l'URL associée à Vault.
   4. <your_role_id>: Remplacer par l'ID de votre AppRole associé dans Vault.
   5. <your_secret_id>: Remplacer par le Secret ID associé à votre AppRole dans Vault.

## Redémarrage de Rundeck

1. Après avoir effectué toutes les configurations, redémarrez Rundeck pour appliquer les changements :
   ```
   sudo systemctl restart rundeckd
   ```

## Test de la Configuration

1. Redémarrez Rundeck pour appliquer les changements.
2. Essayez de lire un secret depuis Rundeck pour vérifier que la configuration fonctionne correctement.

## Conclusion

Vous avez maintenant configuré avec succès le plugin Vault pour Rundeck. Assurez-vous de garder vos identifiants AppRole sécurisés et de mettre à jour régulièrement vos politiques de sécurité.
