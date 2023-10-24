Copy environment file sample to .env and set your configs.   
*Most users only need to edit `ACCOUNT_NAME` and `MONIKER_NAME`*
```shell
cp .env.sample .env
```
run below command and follow the instructions to import your wallet or create a new one.   
if you intend to create a new wallet, you keys will be displayed on screen **only one time**!   
**Don't forget to backup your newly generated account keys. Store it somewhere safe**
```shell
docker compose run --rm node init
```
this will also create a new `priv_json_validator.json` file, if you want to import your previous validator copy it into the volume as follow :
1. inside the repository directory, create a folder called `backup_validator_keys`, then put your `priv_json_validator.json` and `node_key.json` inside it
2. run the copy helper command
```shell
./helpers.sh node:restore [VOLUME_NAME_HERE]
```
otherwise **make a backup from newly generated files and keep them safe**

**THESE KEYS CANNOT BE RESTORED USING MNEMONIC** so make a backup from these too
```shell
./helpers.sh node:backup [VOLUME_NAME_HERE]
```

#### get snapshot
```shell
docker compose run --rm node update-snapshot
```
### Run your node

```shell
docker compose up -d
```