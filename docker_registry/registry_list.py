#!/usr/bin/env python3
import requests

# URL zu deinem Docker-Registry
registry_url = "http://10.0.22.25:5000"

def list_repositories():
    response = requests.get(f"{registry_url}/v2/_catalog")
    response.raise_for_status()  # Fehlerbehandlung
    repos = response.json().get("repositories", [])
    return repos

def list_tags(repository):
    response = requests.get(f"{registry_url}/v2/{repository}/tags/list")
    response.raise_for_status()  # Fehlerbehandlung
    tags = response.json().get("tags", [])
    return tags

def main():
    repos = list_repositories()
    if not repos:
        print("Keine Repositories gefunden.")
        return

    print("Verfügbare Repositories:")
    for i, repo in enumerate(repos):
        print(f"{i + 1}. {repo}")

    choice = int(input("\nWelches Repository möchten Sie genauer ansehen? (Nummer eingeben): "))
    selected_repo = repos[choice - 1]

    print(f"\nTags für Repository '{selected_repo}':")
    tags = list_tags(selected_repo)
    if not tags:
        print("Keine Tags gefunden.")
    else:
        for tag in tags:
            print(tag)

if __name__ == "__main__":
    main()
