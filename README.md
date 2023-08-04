# Jellyfin Filename as Title

A scheduler to rename all video titles

## Usage

### docker run

```shell
docker run -d \
  -e "USER_NAME=${USER_NAME}" \
  -e "API_TOKEN=${API_TOKEN}" \
  -e "BASE_URI=${BASE_URI}" \
  --name jellyfin-filename-as-title \
  --restart unless-stopped \
  ghcr.io/flandredaisuki/jellyfin-filename-as-title
```

### docker compose

```shell
# clone this project
git clone git@github.com:FlandreDaisuki/jellyfin-filename-as-title.git
cd jellyfin-filename-as-title

# modify `.env.example` then rename it to `.env`
mv .env.example .env

docker-compose up -d
```
