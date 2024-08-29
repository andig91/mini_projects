import requests

# URL zu deinem Docker-Registry
registry_url = "http://10.0.22.25:5000"

def list_tags(repository):
    url = f"{registry_url}/v2/{repository}/tags/list"
    response = requests.get(url)
    response.raise_for_status()  # Fehlerbehandlung
    tags = response.json().get("tags", [])
    return tags

def get_manifest_digest(repository, tag):
    url = f"{registry_url}/v2/{repository}/manifests/{tag}"
    headers = {
        "Accept": (
            "application/vnd.oci.image.index.v1+json, "
            "application/vnd.docker.distribution.manifest.v2+json"
        )
    }
    response = requests.get(url, headers=headers)
    
    response.raise_for_status()  # Fehlerbehandlung
    return response.headers.get('Docker-Content-Digest')

def delete_tag(repository, tag):
    digest = get_manifest_digest(repository, tag)
    if not digest:
        print(f"Der Tag '{tag}' in Repository '{repository}' konnte nicht gefunden werden.")
        return False

    url = f"{registry_url}/v2/{repository}/manifests/{digest}"
    response = requests.delete(url)
    if response.status_code == 202:
        print(f"Tag '{tag}' in Repository '{repository}' erfolgreich gelöscht.")
        return True
    else:
        print(f"Fehler beim Löschen von Tag '{tag}' in Repository '{repository}'. Statuscode: {response.status_code}")
        return False

def delete_repository(repository):
    tags = list_tags(repository)
    if not tags:
        print(f"Keine Tags gefunden in Repository '{repository}'.")
        return

    for tag in tags:
        delete_tag(repository, tag)

    print(f"Repository '{repository}' erfolgreich gelöscht.")

def main():
    repository = input("Geben Sie den Namen des Repositories ein, das Sie löschen möchten: ")
    confirm = input(f"Sind Sie sicher, dass Sie das Repository '{repository}' komplett löschen möchten? (ja/nein): ")
    
    if confirm.lower() == 'ja':
        delete_repository(repository)
    else:
        print("Löschvorgang abgebrochen.")

if __name__ == "__main__":
    main()
