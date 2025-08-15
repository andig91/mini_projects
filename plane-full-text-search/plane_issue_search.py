#!/usr/bin/env python3
"""
Plane Issue Search (bundled output + flexible match modes)

Beschreibung:
    - Durchsucht alle Projekte/Issues in einem Plane-Workspace.
    - Sucht in `name` und `description_html` (HTML wird zu Klartext normalisiert).
    - Bündelt Treffer PRO ISSUE (nicht jede Fundstelle einzeln).
    - Gibt pro Feld (name/description) bis zu N Kontext-Snippets aus (5 Wörter davor/danach, konfigurierbar).
    - Unterstützt Match-Modi:
        * --match=all     : UND-Suche (alle Wörter müssen vorkommen) [Default]
        * --match=any     : ODER-Suche (mind. ein Wort reicht)
        * --match=phrase  : Exakte Phrase (Wörter exakt nacheinander)
    - Optional: JSON-Ausgabe für Weiterverarbeitung.

    
Aufrufbeispiele:
    # UND-Suche nach zwei Wörtern (Default), 5-Wort-Kontext, 3 Snippets pro Feld
    python3 plane_issue_search.py "zahlung fehler" \
    --window=5 \
    --max-snippets=3 \
    --match=all

    # Exakte Phrase (Wörter direkt nacheinander)
    python3 plane_issue_search.py "zahlung fehler" --match=phrase

    # ODER-Suche (mind. eines der Wörter)
    python3 plane_issue_search.py "zahlung fehler" --match=any
"""

from __future__ import annotations
import argparse
import html as htmllib
import json
import os
import re
import sys
from typing import Dict, Iterable, List, Optional, Tuple, DefaultDict
from collections import defaultdict

import requests


# ------------------------------ Hilfsfunktionen ------------------------------

def html_to_text(s: Optional[str]) -> str:
    """Wandelt HTML in Text um (Tags entfernen, Entities decodieren)."""
    if not s:
        return ""
    # Entities zuerst decodieren, dann Tags entfernen
    s = htmllib.unescape(s)
    # Script/Style-Inhalte entfernen (ohne Backreferences, stabil für simple Parser)
    s = re.sub(r"<(?:script|style)[^>]*>.*?</(?:script|style)>", " ", s, flags=re.IGNORECASE | re.DOTALL)
    # Alle übrigen Tags entfernen
    s = re.sub(r"<[^>]+>", " ", s)
    # Whitespace normalisieren
    s = re.sub(r"\s+", " ", s).strip()
    return s


def find_word_index(word_spans: List[Tuple[int, int]], pos: int) -> Optional[int]:
    """Gibt den Index des Wortes zurück, das die Zeichenposition `pos` enthält."""
    lo, hi = 0, len(word_spans) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        start, end = word_spans[mid]
        if start <= pos < end:
            return mid
        if pos < start:
            hi = mid - 1
        else:
            lo = mid + 1
    return None


def contexts_around_matches(text: str, query: str, window: int = 5, case_sensitive: bool = False) -> List[str]:
    """Findet alle Vorkommen von `query` (Teilstring/Phrase) in `text` und liefert Kontext (window Wörter vorher/nachher)."""
    if not text or not query:
        return []

    flags = 0 if case_sensitive else re.IGNORECASE
    pattern = re.compile(re.escape(query), flags)

    # Wörter und ihre Spannen vorbereiten
    word_iter = list(re.finditer(r"\S+", text))
    words = [m.group(0) for m in word_iter]
    word_spans = [m.span() for m in word_iter]

    contexts: List[str] = []
    for m in pattern.finditer(text):
        start_char = m.start()
        end_char = m.end() - 1
        start_word_idx = find_word_index(word_spans, start_char)
        end_word_idx = find_word_index(word_spans, end_char)
        if start_word_idx is None or end_word_idx is None:
            continue
        a = max(0, start_word_idx - window)
        b = min(len(words), end_word_idx + window + 1)
        context = " ".join(words[a:b])
        contexts.append(context)

    # Duplikate entfernen, Reihenfolge beibehalten
    seen = set()
    deduped = []
    for c in contexts:
        if c not in seen:
            deduped.append(c)
            seen.add(c)
    return deduped


def tokenize(q: str) -> List[str]:
    """Einfaches Tokenizing des Query-Strings in Wörter (Unicode)."""
    tokens = re.findall(r"\w+", q, flags=re.UNICODE)
    return [t for t in tokens if t]


def contains_all_words(text: str, tokens: List[str], case_sensitive: bool = False) -> bool:
    if not tokens:
        return False
    if not case_sensitive:
        text_cf = text.casefold()
        return all(t.casefold() in text_cf for t in tokens)
    return all(t in text for t in tokens)


def contexts_for_tokens(text: str, tokens: List[str], window: int, case_sensitive: bool) -> List[str]:
    """Kontexte um mehrere Token sammeln und deduplizieren."""
    contexts: List[str] = []
    for t in tokens:
        contexts.extend(contexts_around_matches(text, t, window=window, case_sensitive=case_sensitive))
    # deduplizieren & stabile Ordnung
    seen = set()
    unique = []
    for c in contexts:
        if c not in seen:
            unique.append(c)
            seen.add(c)
    return unique


# ------------------------------ API-Client ------------------------------

class PlaneClient:
    def __init__(self, base_url: str, workspace: str, api_key: str, timeout: int = 30):
        self.base_url = base_url.rstrip("/")
        self.workspace = workspace
        self.timeout = timeout
        self.s = requests.Session()
        self.s.headers.update({
            "x-api-key": api_key,
            "Accept": "application/json",
            "User-Agent": "plane-issue-search/1.2",
        })

    def _get(self, url: str) -> dict:
        r = self.s.get(url, timeout=self.timeout)
        r.raise_for_status()
        try:
            return r.json()
        except requests.JSONDecodeError:
            # Fallback falls requests.JSONDecodeError nicht verfügbar ist (requests<2.27)
            import json as _json
            try:
                return _json.loads(r.text)
            except Exception as e:
                raise RuntimeError(f"Antwort ist kein gültiges JSON: {url}\n{r.text[:1000]}") from e

    def projects(self) -> List[dict]:
        url = f"{self.base_url}/api/v1/workspaces/{self.workspace}/projects/"
        results: List[dict] = []
        while url:
            data = self._get(url)
            results.extend(data.get("results", []))
            url = data.get("next")
        return results

    def issues_for_project(self, project_id: str) -> Iterable[dict]:
        url = f"{self.base_url}/api/v1/workspaces/{self.workspace}/projects/{project_id}/issues"
        while url:
            data = self._get(url)
            for issue in data.get("results", []):
                yield issue
            url = data.get("next")


# ------------------------------ Hauptlogik ------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description="Suche in Plane-Issues mit Kontextausgabe (gebündelt pro Issue).")
    parser.add_argument("query", help="Suchstring. Standard: alle Wörter müssen vorkommen (AND). Für exakte Phrase --match=phrase.")
    parser.add_argument("--config", default="config.json", help="Pfad zur JSON-Konfigurationsdatei")
    #parser.add_argument("--api-key", dest="api_key", default=os.environ.get("PLANE_API_KEY"), help="API-Key oder via PLANE_API_KEY")
    #parser.add_argument("--base-url", default="https://plane.<your-doamin>.com", help="Basis-URL der Plane-Instanz")
    #parser.add_argument("--workspace", default="<workspace>", help="Workspace-Slug (z.B. 'testwork')")
    parser.add_argument("--window", type=int, default=5, help="Anzahl Wörter vor/nach dem Treffer pro Snippet")
    parser.add_argument("--case-sensitive", action="store_true", help="Groß/Kleinschreibung beachten")
    parser.add_argument("--show-json", action="store_true", help="Gefundene Treffer zusätzlich als JSON ausgeben")
    parser.add_argument("--match", choices=["all", "any", "phrase"], default="all", help="Match-Modus: 'all' (AND), 'any' (OR), 'phrase' (exakte Reihenfolge)")
    parser.add_argument("--max-snippets", type=int, default=3, help="Max. Anzahl Snippets je Feld (Name/Beschreibung) und Issue")

    args = parser.parse_args()

    # if not args.api_key:
    #     print("Fehler: API-Key fehlt. Nutze --api-key oder setze PLANE_API_KEY.", file=sys.stderr)
    #     return 2

    if not os.path.isfile(args.config):
        print(f"Konfigurationsdatei nicht gefunden: {args.config}", file=sys.stderr)
        return 2

    with open(args.config, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    args.base_url = cfg.get("base_url")
    args.api_key = cfg.get("api_key")
    args.workspace = cfg.get("workspace")

    client = PlaneClient(args.base_url, args.workspace, args.api_key)

    if not args.base_url or not args.api_key:
        print("base_url oder api_key fehlen in der Konfiguration", file=sys.stderr)
        return 2
    
    try:
        projects = client.projects()
    except requests.HTTPError as e:
        print(f"HTTP-Fehler beim Laden der Projekte: {e}", file=sys.stderr)
        return 1

    # Map: project_id -> identifier
    project_identifier: Dict[str, str] = {}
    for p in projects:
        pid = str(p.get("id"))
        identifier = p.get("identifier") or ""
        if pid and identifier:
            project_identifier[pid] = identifier

    if not project_identifier:
        print("Keine Projekte gefunden oder fehlende Felder 'id'/'identifier'.")
        return 0

    # Aggregation gebündelt pro Issue-ID
    grouped: Dict[str, dict] = {}

    tokens = tokenize(args.query)

    for pid, identifier in project_identifier.items():
        try:
            for issue in client.issues_for_project(pid):
                issue_id = str(issue.get("id"))
                sequence_id = issue.get("sequence_id")
                name = (issue.get("name") or "").strip()
                desc_text = html_to_text(issue.get("description_html") or "")

                # Je Feld prüfen + Kontexte sammeln
                field_contexts: DefaultDict[str, List[str]] = defaultdict(list)

                def handle_field(field_name: str, text: str):
                    if not text:
                        return
                    if args.match == "phrase":
                        ctxs = contexts_around_matches(text, args.query, window=args.window, case_sensitive=args.case_sensitive)
                        if ctxs:
                            field_contexts[field_name].extend(ctxs)
                    elif args.match == "all":
                        if contains_all_words(text, tokens, case_sensitive=args.case_sensitive):
                            ctxs = contexts_for_tokens(text, tokens, window=args.window, case_sensitive=args.case_sensitive)
                            if ctxs:
                                field_contexts[field_name].extend(ctxs)
                    else:  # any
                        ctxs = contexts_for_tokens(text, tokens, window=args.window, case_sensitive=args.case_sensitive)
                        if ctxs:
                            field_contexts[field_name].extend(ctxs)

                handle_field("name", name)
                handle_field("description_html", desc_text)

                # Wenn kein Feld Treffer hat, nächstes Issue
                if not field_contexts:
                    continue

                # Bundling: pro Feld deduplizieren + schneiden auf max_snippets
                for k in list(field_contexts.keys()):
                    seen = set()
                    unique = []
                    for c in field_contexts[k]:
                        if c not in seen:
                            unique.append(c)
                            seen.add(c)
                    field_contexts[k] = unique[: max(0, args.max_snippets)]

                url = f"{args.base_url.rstrip('/')}/{args.workspace}/browse/{identifier}-{sequence_id}/"

                grouped[issue_id] = {
                    "project_identifier": identifier,
                    "issue_id": issue_id,
                    "sequence_id": sequence_id,
                    "title": name,
                    "url": url,
                    "contexts": dict(field_contexts),
                }
        except requests.HTTPError as e:
            print(f"HTTP-Fehler beim Laden der Issues für Projekt {identifier} ({pid}): {e}", file=sys.stderr)
            continue

    if not grouped:
        print("Keine Treffer gefunden.")
        return 0

    # Ausgabe: gebündelt pro Issue
    for issue_id, hit in grouped.items():
        print("\n=== Treffer (gebündelt pro Issue) ===")
        print(f"Projekt:     {hit['project_identifier']}")
        print(f"Issue:       {hit['title']} (#{hit['sequence_id']}, id={hit['issue_id']})")
        print(f"URL:         {hit['url']}")
        for field, ctxs in hit["contexts"].items():
            print(f"  Feld: {field}")
            for i, ctx in enumerate(ctxs, 1):
                print(f"    {i:>2}. … {ctx} …")

    if args.show_json:
        # JSON-ready Struktur
        json_out = []
        for hit in grouped.values():
            json_out.append({
                "project_identifier": hit["project_identifier"],
                "issue_id": hit["issue_id"],
                "sequence_id": hit["sequence_id"],
                "title": hit["title"],
                "url": hit["url"],
                "contexts": hit["contexts"],
            })
        print("\nJSON-Ausgabe:")
        print(json.dumps(json_out, ensure_ascii=False, indent=2))

    return 0


if __name__ == "__main__":
    sys.exit(main())
