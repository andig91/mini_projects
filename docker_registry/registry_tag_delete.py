#!/usr/bin/env python3

import requests

# URL zu deinem Docker-Registry
registry_url = "http://10.0.22.25:5000"

def get_manifest_digest(repository, tag):
    url = f"{registry_url}/v2/{repository}/manifests/{tag}"
    headers = {
        "Accept": (
            "application/vnd.oci.image.index.v1+json, "
            "application/vnd.docker.distribution.manifest.v2+json"
        )
    }
    response = requests.get(url, headers=headers)
    
    # Fehlerbehandlung, wenn der Tag oder das Repository nicht gefunden wird
    try:
        response.raise_for_status()
    except requests.exceptions.HTTPError as e:
        print(f"HTTP Error: {e}")
        print(f"URL: {response.url}")
        print(f"Status Code: {response.status_code}")
        print("Überprüfe den Repository-Namen und den Tag.")
        return None

    return response.headers.get('Docker-Content-Digest')

def delete_tag(repository, tag):
    digest = get_manifest_digest(repository, tag)
    if not digest:
        print("Der Tag konnte nicht gelöscht werden, da der Digest nicht gefunden wurde.")
        return

    url = f"{registry_url}/v2/{repository}/manifests/{digest}"
    response = requests.delete(url)
    if response.status_code == 202:
        print(f"Tag '{tag}' in Repository '{repository}' erfolgreich gelöscht.")
    else:
        print(f"Fehler beim Löschen von Tag '{tag}' in Repository '{repository}'. Statuscode: {response.status_code}")

def main():
    repository = input("Geben Sie den Namen des Repositories ein: ")
    tag = input("Geben Sie den Tag ein, den Sie löschen möchten: ")
    delete_tag(repository, tag)

if __name__ == "__main__":
    main()
